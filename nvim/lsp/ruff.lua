return {
  on_attach = function(client)
    -- Disable formatting — conform.nvim handles it via ruff_format
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}
