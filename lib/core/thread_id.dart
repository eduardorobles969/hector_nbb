String buildThreadId(String a, String b) {
  return (a.compareTo(b) <= 0) ? '${a}__$b' : '${b}__$a';
}
