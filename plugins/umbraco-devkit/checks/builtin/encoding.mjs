// A changed text file that isn't valid UTF-8, such as a Windows-1252 dash pasted into a C# file.
// Compilers and diff tools read it differently on each machine.

const TEXT = /\.(cs|csproj|props|targets|cshtml|razor|json|ts|tsx|js|mjs|cjs|css|scss|html|md|xml|config|yml|yaml|txt|sql|ps1|sh)$/i;

export default {
  name: "encoding",
  files: (path) => TEXT.test(path),
  checkFile({ text }) {
    return text === null ? [{ message: "not valid UTF-8; save it as UTF-8" }] : [];
  },
};
