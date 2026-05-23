// ── CUSTOM CURSOR ──────────────────────────────────
const cur  = document.getElementById('cursor');
const ring = document.getElementById('cursor-ring');

document.addEventListener('mousemove', e => {
  cur.style.left  = e.clientX + 'px';
  cur.style.top   = e.clientY + 'px';
  ring.style.left = e.clientX + 'px';
  ring.style.top  = e.clientY + 'px';
});

// ── MINI BAR CHART ─────────────────────────────────
const chartEl = document.getElementById('miniChart');
const barData = [
  { h: 55, t: 'income'  },
  { h: 30, t: 'expense' },
  { h: 70, t: 'income'  },
  { h: 45, t: 'expense' },
  { h: 60, t: 'income'  },
  { h: 20, t: 'expense' },
  { h: 80, t: 'income'  },
  { h: 50, t: 'expense' },
  { h: 40, t: 'income'  },
  { h: 65, t: 'income'  },
  { h: 35, t: 'expense' },
  { h: 90, t: 'income'  },
];

barData.forEach(d => {
  const b = document.createElement('div');
  b.className    = 'bar ' + d.t;
  b.style.height = d.h + '%';
  b.title        = d.t;
  chartEl.appendChild(b);
});

// ── SCROLL REVEAL ──────────────────────────────────
const revealObserver = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) e.target.classList.add('visible');
  });
}, { threshold: 0.12 });

document.querySelectorAll('.reveal').forEach(el => revealObserver.observe(el));

// ── STAGGERED FEATURE CARDS ────────────────────────
document.querySelectorAll('.features-grid .feat-card').forEach((el, i) => {
  el.style.transitionDelay = (i * 0.07) + 's';
});

// ── STAGGERED STEP ITEMS ───────────────────────────
document.querySelectorAll('.step').forEach((el, i) => {
  el.style.opacity   = 0;
  el.style.transform = 'translateY(24px)';
  el.style.transition = `opacity .6s ${i * 0.12}s ease, transform .6s ${i * 0.12}s ease`;
});

const stepObserver = new IntersectionObserver(entries => {
  entries.forEach(e => {
    if (e.isIntersecting) {
      document.querySelectorAll('.step').forEach(s => {
        s.style.opacity   = 1;
        s.style.transform = 'none';
      });
    }
  });
}, { threshold: 0.1 });

const stepsEl = document.querySelector('.steps');
if (stepsEl) stepObserver.observe(stepsEl);

// ── PARALLAX BLOBS ON MOUSE MOVE ───────────────────
const blob1 = document.querySelector('.blob-1');
const blob2 = document.querySelector('.blob-2');

document.addEventListener('mousemove', e => {
  const x = (e.clientX / window.innerWidth  - 0.5) * 30;
  const y = (e.clientY / window.innerHeight - 0.5) * 30;
  blob1.style.transform = `translate(${x * 0.6}px, ${y * 0.6}px)`;
  blob2.style.transform = `translate(${-x * 0.4}px, ${-y * 0.4}px)`;
});

// ── NAV SCROLL STYLE ───────────────────────────────
const nav = document.querySelector('nav');

window.addEventListener('scroll', () => {
  if (window.scrollY > 60) {
    nav.style.background   = '#0b0d0ff0';
    nav.style.borderBottom = '1px solid #1e2329';
  } else {
    nav.style.background   = 'linear-gradient(to bottom, #0b0d0fee, transparent)';
    nav.style.borderBottom = 'none';
  }
});

// ── SMOOTH ANCHOR SCROLL ───────────────────────────
document.querySelectorAll('a[href^="#"]').forEach(a => {
  a.addEventListener('click', e => {
    const target = document.querySelector(a.getAttribute('href'));
    if (target) {
      e.preventDefault();
      target.scrollIntoView({ behavior: 'smooth' });
    }
  });
});