const fs = require('fs');
const path = require('path');
const qs = require('qs');

// Use path.join to combine __dirname with the relative path to test_cases.json
const filePath = path.join(__dirname, 'test_cases.json');
const e2eTestCases = JSON.parse(fs.readFileSync(filePath).toString());

e2eTestCases.forEach(testCase => {
    let encoded = qs.stringify(testCase.data);
    let decoded = qs.parse(encoded);
    console.log('Encoded: ' + encoded);
    console.log('Decoded: ' + JSON.stringify(decoded));
});
