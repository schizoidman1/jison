// symbolTable.js

const symbolTable = []; // array de { id, type, scope }
let scopeStack = ['global'];

// Sempre use o topo da stack como escopo corrente!
function setScope(scope) {
    scopeStack.push(scope);
    return scope;
}

function resetScope() {
    scopeStack.pop();
}

function currentScope() {
    return scopeStack[scopeStack.length - 1] || 'global';
}

function addSymbol(id, type, scope) {
    console.log('addSymbol:', { id, type, scope: scope || currentScope, stack: [...scopeStack] });
    symbolTable.push({
        id,
        type: type ? type.toUpperCase() : undefined,
        scope: scope || currentScope()
    });
}



// Procura do escopo mais interno para o mais externo
function lookupSymbol(id, _scopeStack) {
    const stack = _scopeStack || scopeStack;
    for (let s = stack.length - 1; s >= 0; s--) {
        for (let i = symbolTable.length - 1; i >= 0; i--) {
            if (symbolTable[i].id === id && symbolTable[i].scope === stack[s]) {
                return symbolTable[i];
            }
        }
    }
    return undefined;
}

module.exports = {
    symbolTable,
    addSymbol,
    lookupSymbol,
    setScope,
    resetScope,
    scopeStack,
    currentScope
};
