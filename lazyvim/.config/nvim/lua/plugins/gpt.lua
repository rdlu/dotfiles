return {
    "jackMort/ChatGPT.nvim",
    event = "VeryLazy",
    config = function()
        local cfg = {
            openai_params = {
                model = "gpt-3.5-turbo-1106"
            },
            openai_edit_params = {
                model = "gpt-3.5-turbo-1106"
            }
        }
        require("chatgpt").setup(cfg)
    end,
    dependencies = {"MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim"}
}
