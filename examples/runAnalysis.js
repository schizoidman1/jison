// runAnalysis.js
const fs = require('fs');
const parser = require('./parser.js');
const { symbolTable } = require('./Syntax/symbolTable');

// Array para guardar as árvores sintáticas das atribuições
let asts = [];

// Aqui vamos garantir que o parser exporta asts
parser.onAssignment = function(astNode) {
    asts.push(astNode);
};

// Ler arquivo de entrada (escolha pelo argumento da linha de comando)
const inputFile = process.argv[2] || 'entrada_01.txt';
const input = fs.readFileSync(inputFile, 'utf-8');

// Executar parser
try {
    parser.parse(input);
} catch (e) {
    console.error('Erro durante parsing:', e.message);
    process.exit(1);
}

// Função recursiva para imprimir a AST no terminal
function printAst(node, prefix = '', isLast = true) {
    if (!node || typeof node !== 'object') return;
    // Monta a linha atual
    const pointer = prefix.length === 0 ? '' : (isLast ? '└── ' : '├── ');
    let label = node.type;
    if (node.value !== undefined && node.value !== null && typeof node.value !== 'object') {
        label += ` (${JSON.stringify(node.value)})`;
    }
    console.log(prefix + pointer + label);

    // Coleta todos os filhos: left, right, value (se objeto/array), index, field etc.
    let children = [];
    // ASTs comuns: left/right
    if (node.left) children.push({ key: 'left', val: node.left });
    if (node.right) children.push({ key: 'right', val: node.right });

    // Se value for AST
    if (node.value && typeof node.value === 'object') {
        if (Array.isArray(node.value)) {
            // Para listas (como em array_init)
            node.value.forEach((v, i) => children.push({ key: `value[${i}]`, val: v }));
        } else if (node.value.type) {
            children.push({ key: 'value', val: node.value });
        } else {
            // Para casos como array_access: {id, index}
            Object.entries(node.value).forEach(([k, v]) => {
                if (typeof v === 'object') children.push({ key: k, val: v });
            });
        }
    }
    // Extra: se tiver fields tipo index, field, etc
    ['index', 'field', 'params', 'args'].forEach(k => {
        if (node[k] && typeof node[k] === 'object')
            children.push({ key: k, val: node[k] });
    });

    // Imprime filhos recursivamente
    children.forEach((child, idx) =>
        printAst(child.val, prefix + (prefix.length === 0 ? '' : (isLast ? '    ' : '│   ')), idx === children.length - 1)
    );
}


// Printar todas as árvores sintáticas de atribuição
console.log('\n===== ÁRVORES SINTÁTICAS (ASTs) DAS ATRIBUIÇÕES =====');
asts.forEach((ast, idx) => {
    console.log(`Atribuição ${idx + 1}:`);
    printAst(ast, '', true);
    console.log('');
});
console.log('====================================================\n');

// Printar tabela de símbolos
console.log('===== TABELA DE SÍMBOLOS =====');
console.table(
    symbolTable.map((info, idx) => ({
        index: idx,
        Identificador: info.id,
        Tipo: info.type,
        Escopo: info.scope
    }))
);
console.log('==============================');
