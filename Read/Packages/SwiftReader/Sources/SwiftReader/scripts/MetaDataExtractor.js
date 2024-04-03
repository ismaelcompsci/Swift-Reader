import { unzlibSync } from "./foliate-js/vendor/fflate.js";
import { EPUB } from "./foliate-js/epub.js";
import { makeFB2 } from "./foliate-js/fb2.js";
import { makeComicBook } from "./foliate-js/comic-book.js";
import { MOBI, isMOBI } from "./foliate-js/mobi.js";
import * as zip from "./foliate-js/vendor/zip.js";

const makeZipLoader = async (file) => {
  try {
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
  } catch (err) {
    debugMessage("[makeZipLoader] " + err);
  }
};

const blobToBase64 = (blob) =>
  new Promise((resolve) => {
    const reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onloadend = () => resolve(reader.result.split(",")[1]);
  });

/**
 *
 * @param {Blob} file
 * @returns {boolean}
 */
const isZip = async (file) => {
  const arr = new Uint8Array(await file.slice(0, 4).arrayBuffer());
  return (
    arr[0] === 0x50 && arr[1] === 0x4b && arr[2] === 0x03 && arr[3] === 0x04
  );
};

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
    return;
  }
  let book;

  if (await isZip(file)) {
    const loader = await makeZipLoader(file);
    if (isCBZ(file)) {
      book = makeComicBook(loader, file);
    } else if (isFBZ(file)) {
      const { entries } = loader;
      const entry = entries.find((entry) => entry.filename.endsWith(".fb2"));
      const blob = await loader.loadBlob((entry ?? entries[0]).filename);
      book = await makeFB2(blob);
    } else {
      book = await new EPUB(loader).init();
    }
  } else if (await isPDF(file)) {
    console.log("PDF NOT SUPPORTED");
    return;
  } else {
    if (await isMOBI(file)) {
      book = await new MOBI({ unzlib: unzlibSync }).open(file);
    } else if (isFB2(file)) {
      book = await makeFB2(file);
    }
  }

  if (!book) {
    console.log("NO BOOK OBJECT");
    return;
  }

  return book;
};

const getLang = (el) => {
  const lang =
    el.lang ||
    el?.getAttributeNS?.("http://www.w3.org/XML/1998/namespace", "lang");
  if (lang) return lang;
  if (el.parentElement) return getLang(el.parentElement);
};

class MetaDataExtractor {
  path;
  book;

  constructor() {
    console.log("[JS] MetaDataExtractor constructed");
  }
  async initBook(bookPath) {
    console.log("[JS] MetaDataExtractor.initBook");

    this.path = bookPath;
    const test = await (
      await fetch(
        `http://localhost:6571/api/metadata/book?filepath=${bookPath}`,
      )
    ).blob();

    const file = new File([test], bookPath);
    this.book = await getBook(file);
    this.book.metadata.cover = await this.getCover();

    let metadata = JSON.stringify(this.book.metadata);
    return metadata;
  }

  greet() {
    return "Hello, " + this.path + "!";
  }

  getMetadata() {
    return this.book.metadata;
  }

  async getCover() {
    console.log("[JS] MetaDataExtractor.getCover");
    const blob = await this.book.getCover();
    const base64Image = blob ? await blobToBase64(blob) : null;
    return base64Image;
  }
}

var global = window || global;
global.MetaDataExtractor = MetaDataExtractor;

module.exports = MetaDataExtractor;
