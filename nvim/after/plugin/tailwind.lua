local ok, it = pcall(require, "tailwind-tools")
if not ok then return end

it.setup({
    server = { override = false },
    document_color = {
        enabled = true,
        kind = "background",
        debounce = 200,
    },
})

