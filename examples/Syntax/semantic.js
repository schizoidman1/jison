const symbolTableModule = require('./symbolTable'); // IMPORTA O MÓDULO INTEIRO

// Checa equivalência entre tipos do C (simples, expanda conforme necessário)
function areTypesEquivalent(a, b) {
    if (!a || !b) return false;
    a = a.trim().toUpperCase();
    b = b.trim().toUpperCase();
    if (a === b) return true;

    // Equivalências clássicas
    const eq = [
        ['SIGNED', 'INT'],
        ['INT', 'SIGNED'],
        ['UNSIGNED', 'UNSIGNED INT'],
        ['UNSIGNED INT', 'UNSIGNED'],
        ['LONG', 'LONG INT'],
        ['LONG INT', 'LONG'],
        ['SHORT', 'SHORT INT'],
        ['SHORT INT', 'SHORT'],
    ];
    if (eq.some(pair => (a === pair[0] && b === pair[1]) || (a === pair[1] && b === pair[0])))
        return true;

    // Aceita INT[] com ARRAY, ou baseType[] com baseType[]
    if ((a.endsWith('[]') && b === 'ARRAY') || (b.endsWith('[]') && a === 'ARRAY')) return true;

    return false;
}

function inferType(node) {
    console.log('inferType chamado com:', node);
    if (!node) return 'UNKNOWN';

    // Literais básicos
    if (node.type === 'int_lit') return 'INT';
    if (node.type === 'float_lit') return 'FLOAT';
    if (node.type === 'char_lit') return 'CHAR';
    if (node.type === 'string_lit') return 'CHAR*';

    // Cast (ex: (int*)malloc(...))
    if (node.type === 'cast') {
        if (typeof node.value === 'string') return node.value.toUpperCase();
        if (typeof node.value === 'object' && node.value.type) return node.value.type.toUpperCase();
        return 'UNKNOWN';
    }

    // Função (caso malloc, retorna ponteiro)
    if (node.type === 'func_call') {
        if (node.left === 'malloc') return 'POINTER'; // Ponteiro genérico
        return 'UNKNOWN';
    }

    // Identificador (busca na tabela de símbolos)
    if (node.type === 'id') {
        if (/^T\d+$/.test(node.value)) return 'INT'; // temporários do tipo T1, T2, etc.
        const symbol = symbolTableModule.lookupSymbol(node.value);
        if (symbol && symbol.type) return symbol.type.toUpperCase();
        else throw new Error(`Variável não declarada: ${node.value}`);
    }

    // Acesso a array: arr[i]
    if (node.type === 'array_access') {
        const symbol = symbolTableModule.lookupSymbol(node.value.id);
        if (symbol) {
            if (symbol.type === 'ARRAY' && symbol.baseType)
                return symbol.baseType.toUpperCase();
            if (symbol.type.endsWith('[]'))
                return symbol.type.replace(/\[\]$/, '').toUpperCase();
            return symbol.type.toUpperCase();
        } else {
            throw new Error(`Array não declarado: ${node.value.id}`);
        }
    }

    // Acesso a campo de struct
    if (node.type === 'struct_access') {
        return 'UNKNOWN'; // Melhore se implementar tabela de tipos de struct
    }

    // Operações binárias
    if (node.type === 'bin_op') {
        const leftType = inferType(node.left);
        const rightType = inferType(node.right);
        const precedence = ['DOUBLE', 'FLOAT', 'LONG', 'UNSIGNED', 'INT', 'SHORT', 'CHAR'];
        if (leftType === rightType) return leftType;
        if (precedence.indexOf(leftType) < precedence.indexOf(rightType)) return leftType;
        return rightType;
    }

    // Arrays declarados
    if (node.type === 'array') {
        const symbol = symbolTableModule.lookupSymbol(node.value);
        if (symbol && symbol.type) return symbol.type.toUpperCase();
        else return 'ARRAY';
    }

    // Ponteiros
    if (node.type === 'pointer') {
        const baseType = inferType(node.base);
        return (baseType + '*').toUpperCase();
    }

    // Struct, Union, Enum
    if (node.type === 'struct') return 'STRUCT ' + (node.value || '');
    if (node.type === 'union') return 'UNION ' + (node.value || '');
    if (node.type === 'enum') return 'ENUM ' + (node.value || '');

    // Modificadores
    if (['short', 'long', 'unsigned', 'signed', 'const', 'volatile', 'register', 'void'].includes(node.type))
        return node.type.toUpperCase();

    // Sizeof (pode retornar inteiro, padronize INT)
    if (node.type === 'sizeof') return 'INT';

    // Typedefs (caso implemente)
    if (node.type === 'typedef') return 'TYPEDEF ' + (node.value || '');

    // Normalização para tokens como "LONG INT"
    if (typeof node.type === 'string' && /^[A-Z ]+$/.test(node.type)) {
        return node.type.trim();
    }

    return 'UNKNOWN';
}

function semanticCheck(node) {
    if (node.type === 'assign') {
        let idSymbol;
        let lhsType;

        // LHS pode ser id, array_access ou struct_access
        if (node.left.type === 'id') {
            idSymbol = symbolTableModule.lookupSymbol(node.left.value);
            lhsType = idSymbol && idSymbol.type ? idSymbol.type.toUpperCase() : undefined;
        } else if (node.left.type === 'array_access') {
            // Array assignment (arr[i] = ...)
            const symbol = symbolTableModule.lookupSymbol(node.left.value.id);
            idSymbol = symbol;
            if (symbol && symbol.type) {
                if (symbol.type === 'ARRAY' && symbol.baseType) {
                    lhsType = symbol.baseType.toUpperCase();
                } else if (symbol.type.endsWith('[]')) {
                    lhsType = symbol.type.replace(/\[\]$/, '').toUpperCase();
                } else {
                    lhsType = symbol.type.toUpperCase();
                }
            }
        } else if (node.left.type === 'struct_access') {
            lhsType = 'UNKNOWN';
        }

        if (!idSymbol) {
            throw new Error(`Variável não declarada: ${node.left.value && node.left.value.id ? node.left.value.id : node.left.value}`);
        }

        const exprType = inferType(node.right);

        // Usa equivalência de tipos em vez de igualdade direta
        if (lhsType && exprType && lhsType !== 'UNKNOWN' && exprType !== 'UNKNOWN') {
            if (!areTypesEquivalent(lhsType, exprType))
                throw new Error(`Erro semântico: ${lhsType} esperado, ${exprType} encontrado`);
        }
    }
}

module.exports = { semanticCheck, inferType };
