import { NativeModules } from 'react-native';

const { RnHtmlToPdf } = NativeModules;

const pageOptions = {
    orientation: {
        Landscape: 'Landscape',
        Portrait: 'Portrait',
    },

    // Define page size constants in mm : w x h
    //
    // https://developer.android.com/reference/android/print/PrintAttributes.MediaSize.html
    //
    // Android uses mm, iOS page size units are points
    // 1 mm = 2.834646 point; 1 point = 0.352778 mm
    size: {
        A0: { id: 'A0', mm: { w: 841, h: 1189 }},
        A1: { id: 'A1', mm: { w: 594, h: 841 }},
        A2: { id: 'A2', mm: { w: 420, h: 594 }},
        A3: { id: 'A3', mm: { w: 297, h: 420 }},
        A4: { id: 'A4', mm: { w: 210, h: 297 }},
        A5: { id: 'A5', mm: { w: 148, h: 210 }},
        A6: { id: 'A6', mm: { w: 105, h: 148 }},
        A7: { id: 'A7', mm: { w: 74, h: 105 }},
        A8: { id: 'A8', mm: { w: 52, h: 74 }},
        UsGovernmentLetter: { id: 'UsGovernmentLetter', mm: { w: 203.2, h: 266.7 }},
        UsLetter: { id: 'UsLetter', mm: { w: 215.9, h: 279.4 }},
        UsLegal: { id: 'UsLegal', mm: { w: 279.4, h: 355.6 }},
    },
};

// Initialize defaults in JS to reduce maintenance in native modules
const pdfOptionsDefault = {
    page: {
        orientation: pageOptions.orientation.Portrait,
        size: pageOptions.size.UsLetter,
    },    
};

const RNHTMLtoPDF = {
    page: pageOptions,

    async convert(options) {
        // Create default options if user did not specify
        if(!options.page) {
            options.page = pdfOptionsDefault.page;
        }
        if(!options.page.size) {
            options.page.size =  pdfOptionsDefault.page.size;
        }
        if(!options.page.orientation) {
            options.page.orientation =  pdfOptionsDefault.orientation;
        }        
        const result = await RnHtmlToPdf.convert(options);
        return result;
    },
   
};

module.exports = {
  RNHTMLtoPDF,
}


