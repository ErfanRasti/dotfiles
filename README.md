# dotfiles

To use these `dotfiles`:

1. Clone the repo recursively:

  ```sh
  git clone --recurse-submodules https://github.com/ErfanRasti/dotfiles
  ```

2. Install pre-requirements:

  ```sh
  sudo pacman -S stow nvim zoxide yazi lazygit kitty ghostty fish fisher bat fzf fd tmux yq zsh-autosuggestions zsh-syntax-highlighting
  paru -S zsh-theme-powerlevel10k zsh-autocomplete zsh-fast-syntax-highlighting ascii-image-converter
  ```

3. Run:

  ```sh
  stow */
  ```

  If you want to just sync a package use this instead:

  ```sh
  stow nvim/ tmux/
  ```

4. After opening `fish`, updaer `fisher` to get the plugins:

  ```fish
  fisher update
  ```

  Also I open `fish` using `bash`. To make it default:

  ```sh
  ```
