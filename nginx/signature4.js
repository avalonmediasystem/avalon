const mod_hmac = require('crypto');

const NOW = new Date();
const PAYLOAD_HASH = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
const DEFAULT_SIGNED_HEADERS = 'host;x-amz-content-sha256;x-amz-date';

const HOST = process.env["S3_SERVER"];

function getEightDigitDate() {
    const year = NOW.getUTCFullYear();
    const month = NOW.getUTCMonth() + 1;
    const day = NOW.getUTCDate();

    return ''.concat(padWithLeadingZeros(year, 4),
        padWithLeadingZeros(month,2),
        padWithLeadingZeros(day,2));
}

function getAmzDatetime() {
    const hours = NOW.getUTCHours();
    const minutes = NOW.getUTCMinutes();
    const seconds = NOW.getUTCSeconds();
    const eightDigitDate = getEightDigitDate();

    return ''.concat(
        eightDigitDate,
        'T', padWithLeadingZeros(hours, 2),
        padWithLeadingZeros(minutes, 2),
        padWithLeadingZeros(seconds, 2),
        'Z');
}

function padWithLeadingZeros(num, size) {
    const s = "0" + num;
    return s.substr(s.length-size);
}

function signature(r) {
    const accessKeyId = process.env['AWS_ACCESS_KEY_ID'];
    const secretAccessKey = process.env['AWS_SECRET_ACCESS_KEY'];
    const eightDigitDate = getEightDigitDate();
    const amzDatetime = getAmzDatetime();
    const uri = uri_path(r);
    const region = process.env["S3_REGION"];
    const contextString = eightDigitDate + '/' + region + '/s3/aws4_request';

    // Build canonical request
    const canonicalHeaders = 'host:' + HOST + '\n' +
                           'x-amz-content-sha256:' + PAYLOAD_HASH + '\n' +
                           'x-amz-date:' + amzDatetime + '\n';
    const canonicalRequest = 'GET\n' + uri + '\n\n' + canonicalHeaders + '\n'+ DEFAULT_SIGNED_HEADERS + '\n'+ PAYLOAD_HASH;
    const canonicalRequestHash = mod_hmac.createHash('sha256').update(canonicalRequest).digest('hex');

    // Build signature
    const stringToSign = 'AWS4-HMAC-SHA256\n' + amzDatetime + '\n' + contextString + '\n' + canonicalRequestHash;
    const kDate = mod_hmac.createHmac('sha256', 'AWS4' + secretAccessKey).update(eightDigitDate).digest();
    const kRegion = mod_hmac.createHmac('sha256', kDate).update(region).digest();
    const kService = mod_hmac.createHmac('sha256', kRegion).update("s3").digest();
    const kSigning = mod_hmac.createHmac('sha256', kService).update('aws4_request').digest();
    const signature = mod_hmac.createHmac('sha256', kSigning).update(stringToSign).digest('hex');

    // Build authorization header
    const authHeader = 'AWS4-HMAC-SHA256 Credential=' + accessKeyId + '/' + contextString + ',SignedHeaders=' + DEFAULT_SIGNED_HEADERS + ',Signature=' + signature;

    return authHeader;
}

function uri_path(r) {
  const bucket = process.env['S3_BUCKET_NAME'];
  return '/' + bucket + '/' + r.variables.stream;
}

export default {
    signature,
    getAmzDatetime
}
