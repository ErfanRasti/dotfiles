# dotfiles

To use these dotfiles:

1. Clone the repo recursively:

  ```sh
  git clone --recurse-submodules https://github.com/ErfanRasti/dotfiles
  ```

2. Install `stow`:

  ```sh
  sudo pacman -S stow
  ```

3. Run:

  ```sh
  stow */
  ```

  If you want to just sync a package use this instead:

  ```sh
  stow nvim/
  ```

