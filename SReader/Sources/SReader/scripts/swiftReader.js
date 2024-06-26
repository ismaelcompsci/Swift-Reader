import "./foliate-js/view.js";
import { Overlayer } from "./foliate-js/overlayer.js";
import { EPUB } from "./foliate-js/epub.js";
import { makeFB2 } from "./foliate-js/fb2.js";
import { makeComicBook } from "./foliate-js/comic-book.js";
import { MOBI, isMOBI } from "./foliate-js/mobi.js";

import { unzlibSync } from "./foliate-js/vendor/fflate.js";
import * as zip from "./foliate-js/vendor/zip.js";

const isPDF = async (file) => {
  const arr = new Uint8Array(await file.slice(0, 5).arrayBuffer());
  return (
    arr[0] === 0x25 &&
    arr[1] === 0x50 &&
    arr[2] === 0x44 &&
    arr[3] === 0x46 &&
    arr[4] === 0x2d
  );
};

const makeZipLoader = async (file) => {
  zip.configure({ useWebWorkers: false });
  const reader = new zip.ZipReader(new zip.BlobReader(file));
  const entries = await reader.getEntries();
  const map = new Map(entries.map((entry) => [entry.filename, entry]));
  const load =
    (f) =>
    (name, ...args) =>
      map.has(name) ? f(map.get(name), ...args) : null;
  const loadText = load((entry) => entry.getData(new zip.TextWriter()));
  const loadBlob = load((entry, type) =>
    entry.getData(new zip.BlobWriter(type)),
  );
  const getSize = (name) => map.get(name)?.uncompressedSize ?? 0;
  return { entries, loadText, loadBlob, getSize };
};

const getCSS = ({ lineHeight, justify, hyphenate, theme, fontSize }) => `
html, body {
  background: none !important;
  color: ${theme.fg};
}

body {
  background-color: ${theme.bg} !important;
  color: inherit !important;
}

html, body, p, li, blockquote, dd {
    font-size: ${fontSize}%;
    line-height: ${lineHeight} !important;
    text-align: ${justify ? "justify" : "start"};
    -webkit-hyphens: ${hyphenate ? "auto" : "manual"};
    hyphens: ${hyphenate ? "auto" : "manual"};
    -webkit-hyphenate-limit-before: 3;
    -webkit-hyphenate-limit-after: 2;
    -webkit-hyphenate-limit-lines: 2;
    hanging-punctuation: allow-end last;
    widows: 2;
}

html, body, p, li, blockquote, dd {
}
`;

const isZip = async (file) => {
  try {
    const arr = new Uint8Array(await file.slice(0, 4).arrayBuffer());
    return (
      arr[0] === 0x50 && arr[1] === 0x4b && arr[2] === 0x03 && arr[3] === 0x04
    );
  } catch (error) {
    console.log(error);
  }
};

const isCBZ = ({ name, type }) =>
  type === "application/vnd.comicbook+zip" || name.endsWith(".cbz");
const isFB2 = ({ name, type }) =>
  type === "application/x-fictionbook+xml" || name.endsWith(".fb2");
const isFBZ = ({ name, type }) =>
  type === "application/x-zip-compressed-fb2" ||
  name.endsWith(".fb2.zip") ||
  name.endsWith(".fbz");

const getBook = async (file) => {
  if (!file.size) {
    console.log("GETVIEW ERROR not founds");
    return;
  }
  let book;
  if (await isZip(file)) {
    const loader = await makeZipLoader(file);
    if (isCBZ(file)) {
      console.log("[GETVIEW] Making cbz");
      book = makeComicBook(loader, file);
    } else if (isFBZ(file)) {
      console.log("[GETVIEW] Making fbz");
      const { entries } = loader;
      const entry = entries.find((entry) => entry.filename.endsWith(".fb2"));
      const blob = await loader.loadBlob((entry ?? entries[0]).filename);
      book = await makeFB2(blob);
    } else {
      console.log("[GETVIEW] Making epub");
      book = await new EPUB(loader).init();
    }
  } else if (await isPDF(file)) {
    // book = await makePDF(file);
    console.log("PDF NOT SUPPORTED");
  } else {
    if (await isMOBI(file)) {
      console.log("[GETVIEW] Making mobi");
      book = await new MOBI({ unzlib: unzlibSync }).open(file);
    } else if (isFB2(file)) {
      console.log("[GETVIEW] Making fb2");
      book = await makeFB2(file);
    }
  }
  if (!book) {
    console.log("GETVIEW ERROR");
    return;
  }
  return book;
};
const getSelectionRange = (doc) => {
  const sel = doc.getSelection();
  if (!sel.rangeCount) return;
  const range = sel.getRangeAt(0);
  if (range.collapsed) return;
  return range;
};
const frameRect = (frame, rect, sx = 1, sy = 1) => {
  const left = sx * rect.left + frame.left;
  const right = sx * rect.right + frame.left;
  const top = sy * rect.top + frame.top;
  const bottom = sy * rect.bottom + frame.top;
  return {
    left,
    right,
    top,
    bottom,
  };
};
const pointIsInView = ({ x, y }) =>
  x > 0 && y > 0 && x < window.innerWidth && y < window.innerHeight;

const getPosition = (target) => {
  // TODO: vertical text
  const frameElement = (
    target.getRootNode?.() ?? target?.endContainer?.getRootNode?.()
  )?.defaultView?.frameElement;
  const transform = frameElement
    ? getComputedStyle(frameElement).transform
    : "";
  const match = transform.match(/matrix\((.+)\)/);
  const [sx, , , sy] =
    match?.[1]?.split(/\s*,\s*/)?.map((x) => parseFloat(x)) ?? [];
  const frame = frameElement?.getBoundingClientRect() ?? {
    top: 0,
    left: 0,
  };
  const rects = Array.from(target.getClientRects());
  const first = frameRect(frame, rects[0], sx, sy);
  const last = frameRect(frame, rects.at(-1), sx, sy);
  const start = {
    point: {
      x: (first.left + first.right) / 2,
      y: first.top,
    },
    dir: "up",
  };
  const end = {
    point: {
      x: (last.left + last.right) / 2,
      y: last.bottom,
    },
    dir: "down",
  };
  const startInView = pointIsInView(start.point);
  const endInView = pointIsInView(end.point);
  if (!startInView && !endInView)
    return {
      point: {
        x: 0,
        y: 0,
      },
    };
  if (!startInView) return end;
  if (!endInView) return start;
  return start.point.y > window.innerHeight - end.point.y ? start : end;
};
const getLang = (el) => {
  const lang =
    el.lang ||
    el?.getAttributeNS?.("http://www.w3.org/XML/1998/namespace", "lang");
  if (lang) return lang;
  if (el.parentElement) return getLang(el.parentElement);
};

/**
 * playing state
 * location change
 * stop scrolling every word scroll only when at the end
 *
 *
 */

class Reader {
  annotations = new Map();
  annotationsByValue = new Map();
  style = {};
  isPdf;
  isCBZ;
  isAndroid = false;
  constructor() {
      console.log("CONSRUCTED READER")
      window.webkit.messageHandlers.initiatedSwiftReader?.postMessage({initiated: "true"});
      
  }
  async initBook(bookPath, initLocation, ext) {
    this.path = bookPath;
    this.initLocation = initLocation;
    console.log("INITBOOK");

    let bookData = await (await fetch(bookPath)).blob();

    let bookFile = new File([bookData],  ext ? "book" + ext : ext);
    this.isPdf = await isPDF(bookFile);
    this.isCBZ = isCBZ(bookFile);
    this.book = await getBook(bookFile);
    await this.init();

    return true;
  }
  init = async () => {
    this.view = document.createElement("foliate-view");
    await this.view.open(this.book);
    document.body.append(this.view);
    
      if (this.initLocation) {
          if (typeof this.initLocation == "string") {
              this.view.goTo(this.initLocation)
          } else {
              this.view.goToFraction(this.initLocation)
          }
      } else {
          this.view.renderer.next()
      }

    this.handleEvents();

      return true
  };

  handleEvents = () => {
    this.view.addEventListener("load", (e) => this.onLoad(e));

    this.view.addEventListener("relocate", (e) => {
      var { cfi, fraction, location, pageItem, section, time, tocItem } =
        e.detail;
//        console.log(JSON.stringify(e.detail, null, 2))

      if (isNaN(fraction)) {
        fraction = 0.0;
      }

      if (isNaN(location.current)) {
        location.current = 0;
      }

      if (isNaN(location.next)) {
        location.next = 0;
      }

      if (isNaN(location.total)) {
        location.total = 0;
      }

      if (isNaN(section.current)) {
        section.current = 0;
      }

      if (isNaN(section.total)) {
        section.total = 0;
      }

      if (isNaN(time.section)) {
        time.section = 0;
      }

      if (isNaN(time.total)) {
        time.total = 0;
      }

      if (fraction === this.prevFraction) {
        return;
      }

      this.prevFraction = fraction;

      window.webkit.messageHandlers.relocate?.postMessage({
        cfi,
        fraction,
        location,
        pageItem,
        section,
        time,
        tocItem,
        updatedAt: Date.now(),
      });
    });

    this.view.addEventListener("external-link", (e) => {
      e.preventDefault();
    });

    this.view.addEventListener("create-overlay", (e) => {
      const { index } = e.detail;
      const list = this.annotations.get(index);
      if (list) {
        for (const annotation of list) this.view.addAnnotation(annotation);
      }
    });

    this.view.addEventListener("draw-annotation", (e) => {
      const { draw, annotation, doc, range } = e.detail;
      const { color } = annotation;
      if (["underline", "squiggly", "strikethrough"].includes(color)) {
        const { defaultView } = doc;
        const node = range.startContainer;
        const el = node.nodeType === 1 ? node : node.parentElement;
        const { writingMode } = defaultView.getComputedStyle(el);
        draw(Overlayer[color], {
          writingMode,
          color: "red",
        });
      } else {
        draw(Overlayer.highlight, {
          color: color,
        });
      }
    });
  };

  /**
   *
   *
   * @param {Object} e - The event object.
   * @param {Object} e.detail - Details of the event.
   * @param {Document} e.detail.doc - The document object.
   * @param {number} e.detail.index - The index value.
   */
  onLoad = (e) => {
    const { doc, index } = e.detail;
    this.doc = doc;
    this.index = index;

    doc.onclick = (event) => {
      if (!window.webkit.messageHandlers.tapHandler) {
        return;
      }

      // if a its a anchor element do not postMessage
      let element = event.target;

      if (isAnchor(element)) {
          console.log("ANCHOR")
        return;
      }

      if (this.view.renderer.pause) {
          console.log("PAUSED")
        return;
      }

      let hit = this.view.renderer
        .getContents()[0]
        ?.overlayer?.hitTest({ x: event.clientX, y: event.clientY });
        
      if (hit?.length > 0) {
        let annotation = this.annotationsByValue.get(hit?.[0])
        let range = hit?.[1]
        if (!annotation || !range) { return }
        let pos = getPosition(range)
          
          var left = 0, top = 0;
          var width = 0, height = 0;
          if (range.getBoundingClientRect) {
              var rect = range.getBoundingClientRect();
              width = rect.right - rect.left;
              height = rect.bottom - rect.top;
              left = rect.left;
              top = rect.top;
          }
          
        window.webkit.messageHandlers.didTapHighlight.postMessage({
          x: left,
          y: top,
          width,
          height,
          dir: pos.dir,
          value: annotation.value,
          text: range.toString(),
          color: annotation.color,
          index: annotation.index
        });
          
        return;
      }

      window.webkit.messageHandlers.tapHandler.postMessage({
        x: event.clientX,
        y: event.clientY,
      });
    };

    doc.addEventListener("touchend", () => {
        if (this.selection == null) { return }
        const value = this.view.getCFI(index, this.selection.range)

        this.selection.value = value
        this.selection.index = this.index
        if (this.selection) {
          delete  this.selection["range"]
          window.webkit.messageHandlers.selectedText.postMessage(this.selection);
            this.selection = null
        }
    })
      
    doc.addEventListener("selectionchange", () => {
      const range = getSelectionRange(doc);
      if (!range) {
        this.view.renderer.pause = false;
        return;
      }
      
      var left = 0, top = 0;
      var width = 0, height = 0;
      if (range.getBoundingClientRect) {
          var rect = range.getBoundingClientRect();
          width = rect.right - rect.left;
          height = rect.bottom - rect.top;
          left = rect.left;
          top = rect.top;
      }
        
      const text = range.toString();
      const pos = getPosition(range)

      const isSelecting = !!text;

      if (isSelecting) {
        this.view.renderer.pause = true;
      } else {
        this.view.renderer.pause = false;
      }

      this.selection = { text, x: left, y: top, width, height, dir: pos.dir, range: range };
        
    });
  };
    
    removeAnnotation({index, value}) {
        this.annotationsByValue.delete(value)
        this.view.addAnnotation({value: value}, true)
        var annotations = this.annotations.get(index)
        annotations = annotations.filter((ann) => ann.value !== value)
        this.annotations.set(index, annotations)
    }
  setAnnotations = (annotations) => {
    annotations.forEach((ann) => {
      this.view.addAnnotation(ann);
      const list = this.annotations.get(ann.index);
      if (list) list.push(ann);
      else this.annotations.set(ann.index, [ann]);
      this.annotationsByValue.set(ann.value, ann);
    });
  };

    
    makeHighlightCFI = async (cfi, color) => {
        var promise = this.view.addAnnotation({value: cfi, color: color ?? "#FFFF00" });
        var chap = await promise;
        
        const ann = {
            index: chap.index,
            value: cfi,
            color: color
        }
        const list = this.annotations.get(ann.index);
        if (list) list.push(ann);
        else this.annotations.set(ann.index, [ann]);
        this.annotationsByValue.set(ann.value, ann);

        return {index: chap.index, label: chap.label, cfi: cfi};
    }

  setTheme = ({ style, layout }) => {
    Object.assign(this.style, style);
    const { theme } = style;
    const $style = document.documentElement.style;
    $style.setProperty("--bg", theme.bg);
    $style.setProperty("--fg", theme.fg);
    const renderer = this.view?.renderer;
    if (renderer) {
      renderer.setAttribute("flow", layout.flow ? "scrolled" : "paginated");
      renderer.setAttribute("gap", layout.gap * 100 + "%");
      renderer.setAttribute("margin", layout.margin + "px");
      renderer.setAttribute("max-inline-size", layout.maxInlineSize + "px");
      renderer.setAttribute("max-block-size", layout.maxBlockSize + "px");
      renderer.setAttribute("max-column-count", layout.maxColumnCount);
      renderer.setAttribute("animated", layout.animated);
      renderer.setStyles?.(getCSS(this.style));
    }
    if (theme.name !== "light") {
      $style.setProperty("--mode", "screen");
    } else {
      $style.setProperty("--mode", "multiply");
    }
    return true;
  };
}

function isAnchor(element) {
  if (element.tagName.toUpperCase() === "A") {
    return !!element.href || !!element.onclick;
  } else if (element.parentElement) {
    return isAnchor(element.parentElement);
  } else {
    return false;
  }
}

window.globalReader = new Reader();
