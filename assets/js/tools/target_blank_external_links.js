Array.from(document.getElementsByTagName('a')).forEach($link => {
  if ($link.hostname !== window.location.hostname && !$link.classList.contains('target-self')) {
    $link.setAttribute('target', '_blank');
  }
});