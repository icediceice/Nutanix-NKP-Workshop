import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';

// Inject real session name from hostname into display text
const sessionName = window.location.hostname.split('.')[0];
document.querySelectorAll('code, p, td, blockquote').forEach(el => {
  if (el.children.length === 0 && el.textContent.includes('$(session_name)')) {
    el.textContent = el.textContent.replaceAll('$(session_name)', sessionName);
  }
});

// Replace mermaid code blocks with renderable divs before mermaid.run()
document.querySelectorAll('pre code.language-mermaid').forEach(el => {
  const div = document.createElement('div');
  div.className = 'mermaid';
  div.textContent = el.textContent;
  el.closest('pre').replaceWith(div);
});

mermaid.initialize({ startOnLoad: false, theme: 'base' });
await mermaid.run();

// Copy-to-clipboard button on every remaining code block
document.querySelectorAll('pre code').forEach(block => {
  const btn = document.createElement('button');
  btn.textContent = 'Copy';
  btn.className = 'copy-btn';
  btn.addEventListener('click', () => {
    navigator.clipboard.writeText(block.textContent.trim()).then(() => {
      btn.textContent = 'Copied!';
      btn.classList.add('copied');
      setTimeout(() => { btn.textContent = 'Copy'; btn.classList.remove('copied'); }, 2000);
    });
  });
  block.closest('pre').appendChild(btn);
});
