import 'package:flutter/material.dart';

import '../../data/models/prime_lead.dart';

class PrimeLeadCopy {
  const PrimeLeadCopy({
    required this.badge,
    required this.title,
    required this.description,
    required this.successMessage,
    required this.emptyCoachHint,
  });

  final String badge;
  final String title;
  final String description;
  final String successMessage;
  final String emptyCoachHint;
}

PrimeLeadCopy primeLeadCopyForStage(PrimeLeadStage stage) {
  switch (stage) {
    case PrimeLeadStage.pendingAssignment:
      return const PrimeLeadCopy(
        badge: 'En revisión',
        title: 'Estamos vinculando a tu coach',
        description:
            'Revisaremos tus datos y te asignaremos un coach PRIME para completar la activación de tu membresía.',
        successMessage:
            'Recibimos tu información y activamos tu acceso PRIME. Nuestro equipo asignará a tu coach en breve.',
        emptyCoachHint:
            'Tu solicitud está en proceso. Apenas asignemos a tu coach lo verás disponible en la pestaña "Coach".',
      );
    case PrimeLeadStage.coachAssigned:
      return const PrimeLeadCopy(
        badge: 'Coach asignado',
        title: 'Tu coach ya está listo',
        description:
            'Abre la pestaña "Coach" para saludarlo, compartir tus objetivos y revisar los planes personalizados que preparará para ti.',
        successMessage:
            'Tu coach ya está vinculado. Ve a la pestaña "Coach" para comenzar a conversar y coordinar tus planes.',
        emptyCoachHint:
            'Tu coach fue asignado. Si no lo ves en la lista, actualiza la app o escríbenos para validar tu acceso.',
      );
    case PrimeLeadStage.inProgress:
      return const PrimeLeadCopy(
        badge: 'Seguimiento en curso',
        title: 'Seguimos afinando tu acceso PRIME',
        description:
            'Estamos coordinando los últimos detalles para cerrar tu suscripción. Mantente atento a las notificaciones y a la pestaña "Coach".',
        successMessage:
            'Recibimos tu información y seguimos en contacto para finalizar tu activación PRIME. Te avisaremos apenas quede listo.',
        emptyCoachHint:
            'Estamos trabajando en tu activación. Apenas quede lista verás a tu coach disponible en esta sección.',
      );
    case PrimeLeadStage.conversionComplete:
      return const PrimeLeadCopy(
        badge: 'Suscripción activa',
        title: 'Tu membresía PRIME está activa',
        description:
            'Tu suscripción quedó confirmada. Usa la pestaña "Coach" para coordinar entrenamientos, seguimiento y notas personalizadas.',
        successMessage:
            'Tu membresía PRIME está activa. Dirígete a la pestaña "Coach" para revisar tus planes y conversar con el equipo.',
        emptyCoachHint:
            'Tu membresía ya está activa. Si aún no ves a tu coach, contáctanos y lo vinculamos de inmediato.',
      );
    case PrimeLeadStage.unknown:
    default:
      return const PrimeLeadCopy(
        badge: 'Actualización',
        title: 'Estamos revisando tu solicitud',
        description:
            'Nuestro equipo está verificando tu información. Si necesitas ayuda adicional escríbenos para darte seguimiento.',
        successMessage:
            'Tu solicitud fue recibida y la estamos revisando manualmente. Encontrarás las novedades dentro de la pestaña "Coach".',
        emptyCoachHint:
            'Seguimos revisando tu activación. Si necesitas apoyo adicional contáctanos para acelerar el proceso.',
      );
  }
}

Color primeLeadStatusColor(PrimeLeadStage stage) {
  switch (stage) {
    case PrimeLeadStage.pendingAssignment:
      return const Color(0xFFFACC15);
    case PrimeLeadStage.coachAssigned:
      return const Color(0xFF34D399);
    case PrimeLeadStage.inProgress:
      return const Color(0xFFF97316);
    case PrimeLeadStage.conversionComplete:
      return const Color(0xFF60A5FA);
    case PrimeLeadStage.unknown:
    default:
      return const Color(0xFF9CA3AF);
  }
}

String primeLeadSuccessTitle(PrimeLeadStage stage) {
  switch (stage) {
    case PrimeLeadStage.coachAssigned:
      return 'Tu coach está listo';
    case PrimeLeadStage.conversionComplete:
      return 'Tu membresía PRIME está activa';
    default:
      return 'Solicitud enviada';
  }
}
