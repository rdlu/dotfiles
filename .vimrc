call plug#begin('~/.vim/plugged')
    Plug 'Shougo/unite.vim'
    Plug 'tpope/vim-sensible'
    Plug 'bling/vim-airline'
    Plug 'tpope/vim-fugitive'
    Plug 'scrooloose/nerdtree'
    Plug 'scrooloose/syntastic'
    Plug 'kien/ctrlp.vim'
    Plug 'tpope/vim-surround'
    Plug 'altercation/vim-colors-solarized'
    Plug 'scrooloose/nerdcommenter'
    Plug 'tpope/vim-rails'
    Plug 'pangloss/vim-javascript'
    Plug 'airblade/vim-gitgutter'
    Plug 'bling/vim-bufferline'
    Plug 'gcmt/taboo.vim'
    Plug 'mbbill/undotree'
    Plug 'mhinz/vim-signify'
    Plug 'fholgado/minibufexpl.vim'
call plug#end()

syntax enable
set background=dark
colorscheme solarized

set laststatus=2
set noshowmode
