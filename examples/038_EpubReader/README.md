# Example 038: EPUB reader

Run [`038_EpubReader.au3`](../038_EpubReader.au3) with AutoIt x86 or x64. The example downloads [*Laments – Motto and dedication* from Wolne Lektury](https://wolnelektury.pl/media/book/epub/laments-motto-and-dedication.epub) to a per-process temporary folder, copies the reader assets there, maps that folder to `https://udf-virtual-host.example/`, and opens `book.epub` in WebView2. Internet access is needed for the sample download. If it fails, choose an EPUB already on your computer in the AutoIt file dialog. No local HTTP server, Flutter SDK, or npm installation is needed to run the example.

The reader's own toolbar provides chapter navigation, search, bookmarks, annotations, settings, and a file picker for another EPUB. The AutoIt line above WebView2 reports the book title and load status. Closing the window destroys WebView2 and removes the temporary copy of the bundled reader and downloaded sample. The isolated WebView2 profile remains under the user's local application data; the reader can retain its own browser storage there.

For a bounded runtime check, run `038_EpubReader.au3 --smoke`. It exits after the reader reports both `bookloaded` and `displayed`, or after 30 seconds with a nonzero exit code.

## Source and licenses

This example hosts the [epubreader-js](https://github.com/intity/epubreader-js) reader by intity, a fork of [epubjs-reader](https://github.com/futurepress/epubjs-reader). Its published JavaScript bundles and static assets were retrieved on 2026-11-15; the source checkout was [commit `2b3c9b5`](https://github.com/intity/epubreader-js/commit/2b3c9b5b8d3e9514b65103a88dbc5977a3d382e1). The AutoIt host and small `index.html` adaptation are local to this UDF. The example uses the JavaScript reader directly; it does not run the separate Flutter package `flutter_epub_viewer`.

- **epubreader-js:** MIT; [license copy](LICENSE.epubreader-js.txt).
- **epub.js 0.3.93:** BSD-style; [license copy](licenses/epub.js-BSD.txt).
- **JSZip 3.10.1:** MIT or GPLv3; this example uses its MIT option. [License copy](licenses/JSZip-MIT-or-GPLv3.txt).
- **js-md5 0.7.3:** MIT; [license copy](licenses/js-md5-MIT.txt).

The sample EPUB is fetched from Wolne Lektury at runtime and is not redistributed with this repository.
