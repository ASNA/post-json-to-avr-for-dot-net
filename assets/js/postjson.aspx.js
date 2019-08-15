'use strict';

const documentReady = function(fn) {
    if (document.readyState !== 'loading') {
        fn();
    } else {
        document.addEventListener('DOMContentLoaded', fn);
    }
}

const submitJsonPostRequest = function() {
    
    const customer = {
        CMCustNo: 0,
        CMName: 'Neil Young',
        CMAddr1: '123 Broken Arrow Road',
        CMCity: 'Sugar Mountain',  
        CMState: 'CA',
        CMCntry: 'USA',
        CMPostCode: 98216,
        CMActive: '1',
        CMFax: 2104040212,    
        CMPhone: '800-289-2762',
    };        

    // The ES6 way to call the post method:

    axios.post('api/customers', customer, {
        headers: {
            'x-custom-header': 'custom x value',
            'y-custom-header': 'custom y value',
        },
    })
    .then(
        (response) => {
            console.log(response.data.InfoMessage);
        },
        (error) => {
            console.table(error);
        }
    );

    // A more traditional way to call the Axios post method.

    // let promise = axios.post('api/customers', customer, {
    //     headers: {
    //         'x-custom-header': 'custom x value',
    //         'y-custom-header': 'custom y value',
    //     },
    // })

    // promise.then(
    //     function (response) {
    //         console.log(response.data.InfoMessage);
    //     },
    //     function (error) {
    //         console.table(error);
    //     }
    // );
}

documentReady(() => {
    // Set default headers for every Axios request.
    axios.defaults.headers.common = {
        'X-Requested-With': 'XMLHttpRequest'
    };
    
    // Assign click event handler.
    const anchor = document.querySelector('#postjson');
    anchor.addEventListener('click', (e) => {   
        submitJsonPostRequest();              
    });
});