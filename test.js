let str = 'eyJ0eXBlIjoiYmEifQ==';
let bin = atob(str);
let bytes = new Uint8Array(bin.length);
for(let j=0; j<bin.length; j++) bytes[j] = bin.charCodeAt(j);
console.log(JSON.parse(new TextDecoder('utf-8').decode(bytes)));
