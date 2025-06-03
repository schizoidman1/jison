// threeAddress.js
let tempCounter = 0;
function newTemp(prefix = 'T') {
    tempCounter += 1;
    return `${prefix}${tempCounter}`;
}

// Função auxiliar para formatar/gerar expressões recursivamente
function formatExpr(expr) {
    if (typeof expr === 'object' && expr !== null) {
        return generateThreeAddress(expr);
    }
    return expr;
}

function generateThreeAddress(node) {
    if (!node) return null;

    // Atribuição geral (variável simples, array, struct, etc)
    if (node.type === 'assign') {
        let lhs;
        // Trata left do tipo array_access, struct_access ou id normal
        if (node.left.type === 'array_access') {
            const arr = node.left.value.id;
            const idx = generateThreeAddress(node.left.value.index);
            lhs = `${arr}[${idx}]`;
        } else if (node.left.type === 'struct_access') {
            lhs = `${node.left.value.id}.${node.left.value.field}`;
        } else if (node.left.type === 'id') {
            lhs = node.left.value;
        } else {
            lhs = formatExpr(node.left);
        }
        const rhs = generateThreeAddress(node.right);
        const code = `${lhs} = ${rhs}`;
        console.log(`3-address code: ${code}`);
        return lhs;
    }

    // Literais e variáveis
    if (['int_lit', 'float_lit', 'char_lit', 'string_lit'].includes(node.type)) {
        return node.value;
    }
    if (node.type === 'id') {
        return node.value;
    }

    // Operação binária
    if (node.type === 'bin_op') {
        const left = generateThreeAddress(node.left);
        const right = generateThreeAddress(node.right);
        const temp = newTemp();
        console.log(`${temp} = ${left} ${node.value} ${right}`);
        return temp;
    }

    // Cast (ex: (int*)malloc(...))
    if (node.type === 'cast') {
        // Cast de malloc: (int*) malloc(expr)
        if (node.left && node.left.type === 'func_call' && node.left.left === 'malloc') {
            const mallocExpr = generateThreeAddress(node.left.value);
            const mallocTmp = newTemp('Tmalloc');
            console.log(`${mallocTmp} = malloc(${mallocExpr})`);
            return mallocTmp;
        } else {
            // Cast genérico (retorna apenas o valor convertido)
            return generateThreeAddress(node.left);
        }
    }

    // sizeof (padrão: retorna 4)
    if (node.type === 'sizeof') {
        return '4';
    }

    // Chamada de função
    if (node.type === 'func_call') {
        if (node.left === 'malloc') {
            const expr = generateThreeAddress(node.value);
            const mallocTmp = newTemp('Tmalloc');
            console.log(`${mallocTmp} = malloc(${expr})`);
            return mallocTmp;
        } else {
            const args = Array.isArray(node.value)
                ? node.value.map(generateThreeAddress).join(', ')
                : node.value !== null
                    ? generateThreeAddress(node.value)
                    : '';
            const funcTmp = newTemp('Tcall');
            console.log(`${funcTmp} = call ${node.left}(${args})`);
            return funcTmp;
        }
    }

    // arr[i] leitura (array_access como expressão isolada)
    if (node.type === 'array_access') {
        const arrayName = node.value.id;
        const indexExpr = generateThreeAddress(node.value.index);
        const temp = newTemp('Tarr');
        console.log(`${temp} = ${arrayName}[${indexExpr}]`);
        return temp;
    }

    // var.campo leitura (struct_access como expressão isolada)
    if (node.type === 'struct_access') {
        const structVar = node.value.id;
        const field = node.value.field;
        const temp = newTemp('Tstruct');
        console.log(`${temp} = ${structVar}.${field}`);
        return temp;
    }

    // Outros tipos de expressão ou casos futuros...
    return null;
}

module.exports = { generateThreeAddress };
