I have developed a hybrid smart contract called RandomNFT, which possesses the ability to mint an NFT and associate it with a corresponding SVG image. This image is stored on-chain in the tokenURI. The NFT generation process involves three types, each randomly generated based on an array of changes.
For each category, there is an associated JSON that contains the file path of an SVG image and a list of attributes. These elements are packed together and then base64 encoded.
The first category has a 10% chance of being generated, while the second and third categories have a 30% and 60% chance, respectively.
// Category1 = 0 - 9 (10%)
// Category2 = 10 - 39 (30%)
// Category3 = 40 = 99 (60%)

The hybrid smart contract utilizes a random number obtained from Chainlink oracles. This number is then transformed to fit within a range of 0 to 99. Based on this transformed number, the category for the NFT will be determined:
