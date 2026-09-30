/*
 * The site's only script. It replaces the two Bootstrap 3 plugins the site
 * used, collapse (the phone menu button) and dropdown (the nav menus), and so
 * jQuery, which Bootstrap's JavaScript needed. It switches Bootstrap's own CSS
 * classes, so the styles don't change. The 2013-2014 info page sidebars that
 * used the affix plugin are CSS position: sticky in styles/main.less.
 */
(() => {
  'use strict';

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');

  //
  // Collapse
  // --------------------------------------------------

  // Runs done once the element's height transition ends, or after the 0.35 s
  // .collapsing transition should have ended, in case transitionend never fires.
  const afterTransition = (el, done) => {
    let finished = false;
    const finish = () => {
      if (finished) return;
      finished = true;
      el.removeEventListener('transitionend', onEnd);
      done();
    };
    const onEnd = (e) => {
      if (e.target === el) finish();
    };
    el.addEventListener('transitionend', onEnd);
    setTimeout(finish, 400);
  };

  // Shows or hides the element that the button's data-target selects. Like
  // Bootstrap, the element slides by animating its height with .collapsing and
  // ends as .collapse.in when shown and .collapse when hidden.
  const toggleCollapse = (button) => {
    const target = document.querySelector(button.getAttribute('data-target'));
    if (!target || target.classList.contains('collapsing')) return;

    const show = !target.classList.contains('in');
    button.setAttribute('aria-expanded', show);

    if (reduceMotion.matches) {
      target.classList.toggle('in', show);
      return;
    }

    if (show) {
      target.classList.remove('collapse');
      target.classList.add('collapsing');
      // Reading scrollHeight lays out the 0 height first, so the change
      // to the full height animates.
      target.style.height = target.scrollHeight + 'px';
      afterTransition(target, () => {
        target.classList.remove('collapsing');
        target.classList.add('collapse', 'in');
        target.style.height = '';
      });
    } else {
      target.style.height = target.offsetHeight + 'px';
      void target.offsetHeight;
      target.classList.add('collapsing');
      target.classList.remove('collapse', 'in');
      target.style.height = '0';
      afterTransition(target, () => {
        target.classList.remove('collapsing');
        target.classList.add('collapse');
        target.style.height = '';
      });
    }
  };

  //
  // Dropdowns
  // --------------------------------------------------

  const dropdownToggles = document.querySelectorAll('[data-toggle="dropdown"]');

  const isOpen = (toggle) => toggle.parentNode.classList.contains('open');

  const setOpen = (toggle, open) => {
    toggle.parentNode.classList.toggle('open', open);
    toggle.setAttribute('aria-expanded', open);
  };

  const closeDropdowns = () => {
    dropdownToggles.forEach((toggle) => setOpen(toggle, false));
  };

  // Opening one menu closes the others, as in Bootstrap.
  const toggleDropdown = (toggle) => {
    const open = !isOpen(toggle);
    closeDropdowns();
    if (open) {
      setOpen(toggle, true);
      toggle.focus();
    }
  };

  //
  // Events
  // --------------------------------------------------

  // Any click that isn't on a dropdown toggle closes the open menus. A toggle
  // is also a link to the section's page, which is where it goes without
  // JavaScript.
  document.addEventListener('click', (e) => {
    const toggle = e.target.closest('[data-toggle]');
    const type = toggle && toggle.getAttribute('data-toggle');

    if (type === 'dropdown') {
      e.preventDefault();
      toggleDropdown(toggle);
      return;
    }
    closeDropdowns();
    if (type === 'collapse') toggleCollapse(toggle);
  });

  // Bootstrap 3.4.1's dropdown keys, on a toggle or inside its menu. On a
  // closed menu, Space, Up and Down open it. On an open one, Esc closes it and
  // returns focus to the toggle, and Up and Down move between its links.
  document.addEventListener('keydown', (e) => {
    if (!['ArrowUp', 'ArrowDown', 'Escape', ' '].includes(e.key)) return;

    const dropdown = e.target.closest('.dropdown');
    if (!dropdown) return;
    const toggle = dropdown.querySelector('[data-toggle="dropdown"]');
    if (e.target !== toggle && !e.target.closest('.dropdown-menu')) return;

    e.preventDefault();
    const open = isOpen(toggle);
    const escape = e.key === 'Escape';

    if (open === escape) {
      if (escape) toggle.focus();
      toggleDropdown(toggle);
      return;
    }
    if (!open) return;

    const links = Array.from(dropdown.querySelectorAll('.dropdown-menu li:not(.disabled) a'))
      .filter((link) => link.getClientRects().length > 0);
    if (!links.length) return;

    let i = links.indexOf(e.target);
    if (e.key === 'ArrowUp' && i > 0) i--;
    if (e.key === 'ArrowDown' && i < links.length - 1) i++;
    links[Math.max(i, 0)].focus();
  });
})();
