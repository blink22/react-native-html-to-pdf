/*
 *
 * Ed Sutton
 */

package android.print;

import com.facebook.react.bridge.ReadableMap;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import java.io.File;

/**
 * Parses page options
 */
public class PdfOptions {

    private static final String TAG = "PdfOptions";

    private static final String OrientationLandscape = "Landscape";

    private static final double MillimetersToInches = 0.0393701;
    private static final double MillimetersToPoints = 2.83465;

    private static String _pageOrientation = "Portrait";
    private static String _pageId = "";
    private static double _pageHeightMm = 0;
    private static double _pageWidthMm = 0;
    private static boolean _shouldEncode = false;

    // Missing option default values should have been added by JS
    public PdfOptions(final ReadableMap options) {
        _shouldEncode = options.hasKey("base64") ? options.getBoolean("base64") : _shouldEncode;
        
        if (!options.hasKey("page")) {
            throw new IllegalArgumentException("option not found: page");
        }
        final ReadableMap page = options.getMap("page");
        _pageOrientation = page.hasKey("orientation") ? page.getString("orientation") : _pageOrientation;
        if (!page.hasKey("size")) {
            throw new IllegalArgumentException("option not found: page.size");
        }
        final ReadableMap pageSize = page.getMap("size");
        _pageId = pageSize.hasKey("id") ? pageSize.getString("id") : _pageId;
        if (!pageSize.hasKey("mm")) {
            throw new IllegalArgumentException("option not found: page.size.mm");
        }
        final ReadableMap pageSizeMm = pageSize.getMap("mm");
        _pageHeightMm = pageSizeMm.hasKey("h") ? pageSizeMm.getDouble("h") : _pageHeightMm;
        _pageWidthMm = pageSizeMm.hasKey("w") ? pageSizeMm.getDouble("w") : _pageWidthMm;
    }

    public String getPageOrientation() {
        return _pageOrientation;
    }

    // "A4", "UsLetter", etc
    public String getPageId() {
        return _pageId;
    }

    public double getPageHeightMm() {
        return _pageHeightMm;
    }

    public double getPageWidthMm() {
        return _pageWidthMm;
    }

    public boolean getShouldEncode() {
        return _shouldEncode;
    }

    

    public String toString() {
        return String.format("%s Page: %s, %f inch x %f inch ( %f pt x %f pt ) ( %f mm x %f mm )",
                _pageOrientation,
                _pageId,
                _pageWidthMm * MillimetersToInches,
                _pageHeightMm * MillimetersToInches,
                _pageWidthMm * MillimetersToPoints,
                _pageHeightMm * MillimetersToPoints,
                _pageWidthMm,
                _pageHeightMm);
    }

    // How to create a PrintAttributes.MediaSize from page data w x h declared in JS?
    // This switch statement smells like it will be hard to maintain
    public static PrintAttributes.MediaSize getMediaSize(String pageId,
                                                   String orientation) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
            throw new RuntimeException("call requires API level 19");
        }

        PrintAttributes.MediaSize mediaSize = null;
        switch (pageId) {
            case "A0":
                mediaSize = PrintAttributes.MediaSize.ISO_A0;
                break;
            case "A1":
                mediaSize = PrintAttributes.MediaSize.ISO_A1;
                break;
            case "A2":
                mediaSize = PrintAttributes.MediaSize.ISO_A2;
                break;
            case "A3":
                mediaSize = PrintAttributes.MediaSize.ISO_A3;
                break;
            case "A4":
                mediaSize = PrintAttributes.MediaSize.ISO_A4;
                break;
            case "A5":
                mediaSize = PrintAttributes.MediaSize.ISO_A5;
                break;
            case "A6":
                mediaSize = PrintAttributes.MediaSize.ISO_A6;
                break;
            case "A7":
                mediaSize = PrintAttributes.MediaSize.ISO_A7;
                break;
            case "A8":
                mediaSize = PrintAttributes.MediaSize.ISO_A8;
                break;
            case "UsGovernmentLetter":
                mediaSize = PrintAttributes.MediaSize.NA_GOVT_LETTER;
                break;
            case "UsLetter":
                mediaSize = PrintAttributes.MediaSize.NA_LETTER;
                break;
            case "UsLegal":
                mediaSize = PrintAttributes.MediaSize.NA_LEGAL;
                break;
            default:
                mediaSize = PrintAttributes.MediaSize.ISO_A4;
                break;
        }
        if (orientation.equalsIgnoreCase(OrientationLandscape)) {
            return mediaSize.asLandscape();
        }
        return mediaSize;
    }

    public PrintAttributes.MediaSize getMediaSize() {
        return getMediaSize(_pageId, _pageOrientation);
    }

}
