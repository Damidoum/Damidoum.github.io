// The navigation remains fully visible when JavaScript is unavailable.
const menuButton = document.querySelector('.menu-toggle');
const navigation = document.querySelector('#site-nav');
if (menuButton && navigation) {
  menuButton.hidden = false;
  navigation.classList.add('is-enhanced');
  const closeMenu = () => {
    menuButton.setAttribute('aria-expanded', 'false');
    navigation.classList.remove('is-open');
  };
  menuButton.addEventListener('click', () => {
    const open = menuButton.getAttribute('aria-expanded') !== 'true';
    menuButton.setAttribute('aria-expanded', String(open));
    navigation.classList.toggle('is-open', open);
  });
  navigation.addEventListener('click', (event) => { if (event.target.closest('a')) closeMenu(); });
  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && menuButton.getAttribute('aria-expanded') === 'true') { closeMenu(); menuButton.focus(); }
  });
  window.matchMedia('(min-width: 761px)').addEventListener('change', closeMenu);
}

// Place filtering is optional: every photograph remains visible without JavaScript.
const photoLocationFilter = document.querySelector('.photo-location-filter');
const photoGallery = document.querySelector('#photo-gallery');
if (photoLocationFilter && photoGallery) {
  const select = photoLocationFilter.querySelector('select');
  const photos = [...photoGallery.querySelectorAll('[data-photo-location]')];
  const count = document.querySelector('[data-photo-count]');
  const filterPhotos = () => {
    photos.forEach((photo) => { photo.hidden = select.value !== '' && photo.dataset.photoLocation !== select.value; });
    const visible = photos.filter((photo) => !photo.hidden).length;
    if (count) count.textContent = `${visible} ${visible === 1 ? 'photo' : 'photos'}`;
  };
  photoLocationFilter.hidden = false;
  select.addEventListener('change', filterPhotos);
  window.addEventListener('pageshow', filterPhotos);
  filterPhotos();
}
