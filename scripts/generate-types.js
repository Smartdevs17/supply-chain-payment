const fs = require("fs");

async function main() {
  console.log("Generating TypeScript definitions...");
  // Mock generation
  fs.writeFileSync("types.d.ts", "// Auto-generated types");
  console.log("Types generated.");
}

main();
