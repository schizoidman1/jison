// ast.js
function createNode(type, left = null, right = null, value = null, extra = {}) {
    return { type, left, right, value, ...extra };
}

module.exports = { createNode };
