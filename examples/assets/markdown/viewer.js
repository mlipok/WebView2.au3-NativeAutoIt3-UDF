window.updateView = (markdown, baseUrl) => {
  const savedY = window.scrollY;
  document.getElementById('document-base').href = baseUrl;
  const template = document.createElement('template');
  template.innerHTML = marked.parse(markdown, {gfm: true, breaks: false});
  template.content.querySelectorAll('script,iframe,object,embed,style,link,meta,base,form').forEach(node => node.remove());
  template.content.querySelectorAll('*').forEach(node => {
    for (const attribute of [...node.attributes]) {
      if (/^on/i.test(attribute.name) || attribute.name === 'srcdoc') node.removeAttribute(attribute.name);
      if (/^(href|src|xlink:href)$/i.test(attribute.name) && /^\s*(javascript|vbscript):/i.test(attribute.value)) node.removeAttribute(attribute.name);
    }
    if (node.tagName === 'A') { node.removeAttribute('target'); node.rel = 'noopener noreferrer'; }
  });
  document.getElementById('view').replaceChildren(template.content);
  rebuildContents();
  window.scrollTo(0, savedY);
  return true;
};
function rebuildContents() {
  const tree = document.getElementById('toc-tree');
  const headings = [...document.querySelectorAll('#view h1, #view h2, #view h3, #view h4, #view h5, #view h6')];
  tree.replaceChildren();
  document.getElementById('contents').hidden = headings.length === 0;
  const usedIds = new Set([...document.querySelectorAll('[id]')].map(node => node.id));
  const parents = [];
  headings.forEach((heading, index) => {
    if (!heading.id) {
      const base = `md-heading-${index + 1}`;
      let id = base;
      for (let suffix = 2; usedIds.has(id); suffix++) id = `${base}-${suffix}`;
      heading.id = id;
      usedIds.add(id);
    }
    const level = Number(heading.tagName.slice(1));
    while (parents.length && parents[parents.length - 1].level >= level) parents.pop();
    const item = document.createElement('li');
    item.setAttribute('role', 'treeitem');
    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = heading.textContent.trim() || `Heading ${index + 1}`;
    button.addEventListener('click', () => heading.scrollIntoView({block: 'start'}));
    item.append(button);
    if (parents.length) {
      const parent = parents[parents.length - 1].item;
      let group = parent.querySelector(':scope > ul[role="group"]');
      if (!group) {
        group = document.createElement('ul');
        group.setAttribute('role', 'group');
        parent.setAttribute('aria-expanded', 'true');
        parent.append(group);
      }
      group.append(item);
    } else {
      tree.append(item);
    }
    parents.push({level, item});
  });
}
document.addEventListener('click', event => {
  const link = event.target.closest('a');
  if (link && link.getAttribute('href')?.startsWith('#')) {
    event.preventDefault();
    document.getElementById(decodeURIComponent(link.hash.slice(1)))?.scrollIntoView();
  }
});
