import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();

type InsightSignal = "low_energy" | "streak_drop" | "mood_drop";
type InsightSource = "journal" | "activity" | "sleep";

interface JournalSnapshot {
  energy?: number;
  hungerSatiety?: number;
  occurredAt?: admin.firestore.Timestamp;
  type?: string;
}

const FORBIDDEN_WORDS = ["diet", "calorie", "peso", "bmi"];

export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const now = admin.firestore.FieldValue.serverTimestamp();
  const profileRef = db.collection("users").doc(user.uid);
  const defaultProfile = {
    uid: user.uid,
    name: user.displayName ?? "",
    email: user.email ?? "",
    photoUrl: user.photoURL ?? "",
    locale: user.languageCode ?? "es",
    timeZone: "UTC",
    roles: ["user"],
    createdAt: now,
    updatedAt: now,
    preferences: {
      antiDietAgreement: true,
      notifEnabled: true,
    },
  };
  const planRef = db.collection("adaptive_plans").doc(user.uid);
  const plan = {
    uid: user.uid,
    goals: ["Respira profundo 3 veces al día"],
    nutritionNotes: "Observa tu cuerpo sin juicios.",
    movementNotes: "Elige un movimiento disfrutable 10 minutos.",
    habits: ["Celebrar una victoria pequeña"],
    lastCoachReviewAt: now,
    createdAt: now,
    updatedAt: now,
  };
  await Promise.all([profileRef.set(defaultProfile), planRef.set(plan)]);
});

function computeSignals(entries: JournalSnapshot[]): Array<{signal: InsightSignal; score: number}> {
  if (!entries.length) {
    return [];
  }
  const energyValues = entries
    .filter((e) => typeof e.energy === "number")
    .map((e) => e.energy as number);
  const hungerValues = entries
    .filter((e) => typeof e.hungerSatiety === "number")
    .map((e) => e.hungerSatiety as number);

  const avgEnergy = energyValues.length
    ? energyValues.reduce((acc, value) => acc + value, 0) / energyValues.length
    : 0;
  const avgHunger = hungerValues.length
    ? hungerValues.reduce((acc, value) => acc + value, 0) / hungerValues.length
    : 0;

  const signals: Array<{signal: InsightSignal; score: number}> = [];

  if (avgEnergy > 0 && avgEnergy <= 2) {
    signals.push({signal: "low_energy", score: Math.round(10 - avgEnergy * 2)});
  }

  const streakDrop = entries
    .sort((a, b) => (a.occurredAt?.toMillis() ?? 0) - (b.occurredAt?.toMillis() ?? 0))
    .slice(-3)
    .filter((entry) => entry.type === "meal" || entry.type === "mood").length < 2;

  if (streakDrop) {
    signals.push({signal: "streak_drop", score: 6});
  }

  if (avgHunger >= 4 && avgEnergy <= 2) {
    signals.push({signal: "mood_drop", score: 7});
  }

  return signals;
}

export const analyzeSignals = functions.https.onCall(async (data, context) => {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Must be authenticated");
  }
  const {userId} = data as {userId: string};
  if (!userId) {
    throw new functions.https.HttpsError("invalid-argument", "userId is required");
  }
  const since = admin.firestore.Timestamp.fromMillis(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const journalSnap = await db
    .collection("journal")
    .doc(userId)
    .collection("entries")
    .where("occurredAt", ">=", since)
    .get();
  const entries: JournalSnapshot[] = journalSnap.docs.map((d) => d.data() as JournalSnapshot);
  const signals = computeSignals(entries);
  const insights: Array<Record<string, unknown>> = [];
  const now = admin.firestore.FieldValue.serverTimestamp();

  for (const item of signals) {
    const docRef = db.collection("ai_insights").doc(userId).collection("items").doc();
    const insight = {
      uid: docRef.id,
      userId,
      source: "journal" as InsightSource,
      signal: item.signal,
      score: item.score,
      suggestedAction: item.signal === "low_energy"
        ? "Invita a descansar y priorizar autocuidado"
        : item.signal === "streak_drop"
          ? "Consultar motivación y barreras de registro"
          : "Reforzar hábitos que elevan el ánimo",
      createdAt: now,
      handledByCoachUid: null,
    };
    await docRef.set(insight);
    insights.push({...insight, createdAt: Date.now()});
  }

  return {insights};
});

export const notifyCoachOnInsight = functions.firestore
  .document("ai_insights/{userId}/items/{insightId}")
  .onCreate(async (snapshot, context) => {
    const {userId, insightId} = context.params as {userId: string; insightId: string};
    const assignmentSnap = await db.collection("assignments").doc(userId).collection("coaches").get();
    if (assignmentSnap.empty) {
      return;
    }

    const insight = snapshot.data();
    for (const coach of assignmentSnap.docs) {
      const token = coach.data().fcmToken as string | undefined;
      if (!token) continue;
      await messaging.send({
        token,
        notification: {
          title: "Nueva señal de bienestar",
          body: insight.suggestedAction ?? "",
        },
        data: {
          route: `/coach/user/${userId}`,
          insightId,
        },
      });
    }
  });

function sanitizeMarkdown(body: string): string {
  let sanitized = body;
  for (const word of FORBIDDEN_WORDS) {
    const regex = new RegExp(word, "ig");
    sanitized = sanitized.replace(regex, "***");
  }
  return sanitized;
}

export const moderateCommunityPost = functions.firestore
  .document("community/posts/{postId}")
  .onWrite(async (change) => {
    const data = change.after.data();
    if (!data) {
      return;
    }
    const bodyMarkdown = data.bodyMarkdown as string;
    if (!bodyMarkdown) {
      return;
    }
    const sanitized = sanitizeMarkdown(bodyMarkdown);
    if (sanitized !== bodyMarkdown) {
      await change.after.ref.set(
        {bodyMarkdown: sanitized, moderatedAt: admin.firestore.FieldValue.serverTimestamp()},
        {merge: true},
      );
    }
  });
