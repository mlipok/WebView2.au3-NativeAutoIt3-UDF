"use strict";

const h = React.createElement;
const { useEffect, useRef, useState } = React;
const rowsPerPage = 50;
const columnsPerPage = 12;
const copyTypes = {
  xls: { bookType: "biff8", mime: "application/vnd.ms-excel", rows: 65536, columns: 256 },
  xlsx: { bookType: "xlsx", mime: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", rows: 1048576, columns: 16384 }
};

function readWorkbook(bytes) {
  const workbook = XLSX.read(bytes, { type: "array", cellFormula: true, cellNF: true, cellStyles: true });
  if (!workbook.SheetNames.length) throw new Error("The workbook contains no sheets.");
  return workbook;
}

function editCell(sheet, address, value, type) {
  const previous = sheet[address];
  if (previous && (previous.f || previous.F)) throw new Error("Formula cells are read-only.");
  let parsed = value;
  if (type === "n") {
    parsed = Number(value);
    if (!/^[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+-]?\d+)?$/i.test(value.trim()) || !Number.isFinite(parsed)) {
      throw new Error("Enter a number using a decimal point.");
    }
  }
  if (type === "b") {
    if (!/^(true|false)$/i.test(value.trim())) throw new Error("Enter TRUE or FALSE.");
    parsed = value.trim().toLowerCase() === "true";
  }
  if (type !== "z" && typeof parsed === "string" && parsed.length > 32767) {
    throw new Error("A cell can contain up to 32,767 characters.");
  }
  const cell = { ...previous, t: type, v: parsed };
  delete cell.w;
  delete cell.h;
  delete cell.r;
  if (type === "z") delete cell.v;
  sheet[address] = cell;
  if (type !== "z") {
    const pos = XLSX.utils.decode_cell(address);
    const range = sheet["!ref"] ? XLSX.utils.decode_range(sheet["!ref"]) : { s: { ...pos }, e: { ...pos } };
    range.s.r = Math.min(range.s.r, pos.r);
    range.s.c = Math.min(range.s.c, pos.c);
    range.e.r = Math.max(range.e.r, pos.r);
    range.e.c = Math.max(range.e.c, pos.c);
    sheet["!ref"] = XLSX.utils.encode_range(range);
  }
}

function saveWorkbook(workbook, file) {
  const format = copyTypes[file.extension];
  for (const sheetName of workbook.SheetNames) {
    const range = workbook.Sheets[sheetName]["!ref"];
    if (!range) continue;
    const last = XLSX.utils.decode_range(range).e;
    if (last.r >= format.rows || last.c >= format.columns) {
      throw new Error("Sheet " + sheetName + " exceeds the output format's row or column limit.");
    }
  }
  const bytes = XLSX.write(workbook, { bookType: format.bookType, type: "array", cellStyles: true });
  const url = URL.createObjectURL(new Blob([bytes], { type: format.mime }));
  const link = document.createElement("a");
  link.href = url;
  link.download = file.name.slice(0, -file.extension.length - 1) + "-copy." + file.extension;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 60000);
}

function App() {
  const input = useRef(null);
  const editField = useRef(null);
  const grid = useRef(null);
  const openSequence = useRef(0);
  const [file, setFile] = useState(null);
  const [sheetName, setSheetName] = useState("");
  const [cell, setCell] = useState("");
  const [value, setValue] = useState("");
  const [type, setType] = useState("s");
  const [rowPage, setRowPage] = useState(0);
  const [columnPage, setColumnPage] = useState(0);
  const [status, setStatus] = useState("");
  const [dirty, setDirty] = useState(false);
  const [saving, setSaving] = useState(false);
  const [opening, setOpening] = useState(false);
  const sheet = file && file.workbook.Sheets[sheetName];
  const current = cell && sheet[cell];
  const formula = current && (current.f || current.F);
  const format = file && copyTypes[file.extension];
  const end = sheet && sheet["!ref"] ? XLSX.utils.decode_range(sheet["!ref"]).e : { r: 0, c: 0 };
  const rows = format ? Math.min(format.rows, Math.max(20, end.r + 2)) : 0;
  const columns = format ? Math.min(format.columns, Math.max(columnsPerPage, end.c + 2)) : 0;

  useEffect(() => {
    function onSave(event) {
      setSaving(false);
      if (event.detail === "saved") {
        setDirty(false);
        setStatus("Workbook copy saved.");
      } else if (event.detail === "cancelled") {
        setStatus("Save cancelled or the destination already exists.");
      } else {
        setStatus("The workbook copy could not be saved.");
      }
    }
    window.addEventListener("spreadsheet-save", onSave);
    return () => window.removeEventListener("spreadsheet-save", onSave);
  }, []);

  function chooseSheet(name) {
    setSheetName(name);
    setCell("");
    setRowPage(0);
    setColumnPage(0);
    if (grid.current) grid.current.scrollTo(0, 0);
  }

  async function openFile(event) {
    const selected = event.target.files[0];
    event.target.value = "";
    if (!selected) return;
    const ticket = ++openSequence.current;
    const extension = selected.name.split(".").pop().toLowerCase();
    setOpening(true);
    setStatus("Opening workbook…");
    try {
      if (!["xls", "xlsx"].includes(extension)) throw new Error("Choose an .xls or .xlsx file.");
      const workbook = readWorkbook(await selected.arrayBuffer());
      if (ticket !== openSequence.current) return;
      setFile({ name: selected.name, extension, workbook });
      chooseSheet(workbook.SheetNames[0]);
      setDirty(false);
      setStatus("Workbook opened.");
    } catch (error) {
      if (ticket === openSequence.current) setStatus("Open failed. " + error.message);
    } finally {
      if (ticket === openSequence.current) setOpening(false);
    }
  }

  function pick(address, focusEditor) {
    const entry = sheet[address];
    setCell(address);
    setValue(entry ? (entry.f ? "=" + entry.f : String(entry.v ?? "")) : "");
    setType(entry && ["n", "b"].includes(entry.t) ? entry.t : "s");
    if (focusEditor) requestAnimationFrame(() => editField.current?.focus());
  }

  function apply(typeToWrite) {
    if (!cell || formula || saving || opening) return;
    try {
      editCell(sheet, cell, value, typeToWrite);
      if (typeToWrite === "z") setValue("");
      setDirty(true);
      setStatus("Updated " + sheetName + "!" + cell + ".");
    } catch (error) {
      setStatus(error.message);
    }
  }

  function save() {
    if (!file || saving || opening) return;
    if (file.extension === "xls") {
      const hasFormulas = Object.values(file.workbook.Sheets).some((worksheet) =>
        Object.values(worksheet).some((entry) => entry && (entry.f || entry.F)));
      if (hasFormulas && !window.confirm("An XLS copy keeps stored formula results and drops the formulas. Save the copy?")) return;
    }
    setSaving(true);
    try {
      saveWorkbook(file.workbook, file);
      setStatus("Choose where to save the copy.");
    } catch (error) {
      setSaving(false);
      setStatus("Export failed. " + error.message);
    }
  }

  function button(label, handler, props = {}) {
    return h("button", { type: "button", onClick: handler, ...props }, label);
  }

  function changePage(setPage, page) {
    setCell('');
    setPage(page);
    grid.current.scrollTo(0, 0);
  }

  function renderGrid() {
    const rowStart = rowPage * rowsPerPage;
    const columnStart = columnPage * columnsPerPage;
    const rowEnd = Math.min(rows, rowStart + rowsPerPage);
    const columnEnd = Math.min(columns, columnStart + columnsPerPage);
    const headings = Array.from({ length: columnEnd - columnStart }, (_, i) => XLSX.utils.encode_col(columnStart + i));
    const rowElements = [];
    for (let row = rowStart; row < rowEnd; row++) {
      const cells = headings.map((column) => {
        const address = column + (row + 1);
        const entry = sheet[address];
        const display = entry ? XLSX.utils.format_cell(entry) : "";
        return h("td", { key: address }, button(display, () => pick(address, false), {
          className: cell === address ? "selected" : "",
          "aria-label": display ? address + ": " + display : address,
          "aria-pressed": cell === address,
          "data-cell": address,
          title: display,
          onDoubleClick: () => pick(address, true),
          onKeyDown: (event) => {
            if (event.key === "Enter") {
              event.preventDefault();
              pick(address, true);
              return;
            }
            const offsets = { ArrowUp: [-1, 0], ArrowDown: [1, 0], ArrowLeft: [0, -1], ArrowRight: [0, 1] };
            const offset = offsets[event.key];
            if (!offset) return;
            const next = XLSX.utils.decode_cell(address);
            next.r += offset[0];
            next.c += offset[1];
            if (next.r < rowStart || next.r >= rowEnd || next.c < columnStart || next.c >= columnEnd) return;
            event.preventDefault();
            const nextAddress = XLSX.utils.encode_cell(next);
            pick(nextAddress, false);
            grid.current.querySelector('[data-cell="' + nextAddress + '"]').focus();
          },
          tabIndex: cell === address || (!cell && address === headings[0] + (rowStart + 1)) ? 0 : -1
        }));
      });
      rowElements.push(h("tr", { key: row }, h("th", { scope: "row" }, row + 1), cells));
    }
    return h(React.Fragment, null,
      h("div", { className: "grid", ref: grid },
        h("table", { "aria-label": sheetName },
          h("thead", null, h("tr", null, h("th", null, "#"), headings.map((column) => h("th", { scope: "col", key: column }, column)))),
          h("tbody", null, rowElements))),
      h("div", { className: "pager" },
        button("Previous rows", () => changePage(setRowPage, rowPage - 1), { disabled: rowStart === 0 }),
        h("span", null, "Rows " + (rowStart + 1) + "–" + rowEnd + " of " + rows),
        button("Next rows", () => changePage(setRowPage, rowPage + 1), { disabled: rowEnd >= rows }),
        button("Previous columns", () => changePage(setColumnPage, columnPage - 1), { disabled: columnStart === 0 }),
        h("span", null, "Columns " + headings[0] + "–" + headings[headings.length - 1]),
        button("Next columns", () => changePage(setColumnPage, columnPage + 1), { disabled: columnEnd >= columns })));
  }

  const busy = opening || saving;
  return h("main", { className: "workspace" },
    h("div", { className: "toolbar" },
      h("input", { type: "file", hidden: true, ref: input, accept: ".xls,.xlsx", onChange: openFile, "aria-label": "Workbook file" }),
      button("Open workbook…", () => {
        if (!dirty || window.confirm("Open another workbook and discard unsaved edits?")) input.current.click();
      }, { className: "primary", disabled: busy }),
      file && h("span", { className: "filename" }, file.name + (dirty ? " *" : "")),
      file && h("label", null, "Sheet", h("select", { value: sheetName, onChange: (event) => chooseSheet(event.target.value) },
        file.workbook.SheetNames.map((name) => h("option", { key: name }, name)))),
      button("Save copy…", save, { disabled: !file || busy })),
    sheet ? h(React.Fragment, null,
      h("form", { className: "editor", onSubmit: (event) => { event.preventDefault(); apply(type); } },
        h("span", { className: "address" }, cell || "—"),
        h("label", { className: "value-field" }, formula ? "Formula" : "Value",
          h("input", { ref: editField, type: "text", value, disabled: !cell || busy, readOnly: Boolean(formula),
            onChange: (event) => setValue(event.target.value) })),
        h("label", null, "Type", h("select", { value: type, disabled: !cell || Boolean(formula) || busy,
          onChange: (event) => setType(event.target.value) },
          h("option", { value: "s" }, "Text"), h("option", { value: "n" }, "Number"), h("option", { value: "b" }, "Boolean"))),
        h("button", { type: "submit", disabled: !cell || Boolean(formula) || busy }, "Apply edit"),
        button("Clear cell", () => apply("z"), { disabled: !cell || Boolean(formula) || busy })),
      renderGrid()) :
      h("section", { className: "empty" }, h("h1", null, "Spreadsheet editor"), h("p", null, "Open an XLS or XLSX workbook from your computer.")),
    h("p", { className: "status", role: "status" }, status));
}

ReactDOM.createRoot(document.getElementById("root")).render(h(App));
