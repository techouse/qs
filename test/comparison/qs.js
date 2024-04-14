const fs = require('fs');
const qs = require('qs');

const e2eTestCases = JSON.parse(fs.readFileSync('test_cases.json').toString());

e2eTestCases.forEach(testCase => {
    let encoded = qs.stringify(testCase.data);
    let decoded = qs.parse(encoded);
    console.log('Encoded: ' + encoded);
    console.log('Decoded: ' + JSON.stringify(decoded));
});
