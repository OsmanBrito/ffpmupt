bool shouldPreserveAppNavigation(Uri location) {
  return location.fragment.trim().startsWith('/');
}
