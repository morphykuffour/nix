{pkgs, ...}: {
  programs.himalaya = {
    enable = true;
  };

  accounts.email.accounts = {
    uconn_gmail = {
      primary = true;
      himalaya.enable = true;
      address = "morphy.kuffour@uconn.edu";
      realName = "Morphy Kuffour";
      userName = "morphy.kuffour";
      passwordCommand = "'pass show gmail'";
      imap = {
        host = "imap.gmail.com";
        port = 993;
        tls.enable = true;
      };
      smtp = {
        host = "smtp.gmail.com";
        port = 465;
        tls.enable = true;
      };
    };
  };
}
