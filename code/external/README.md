# Third-party code

- **`fdr_bh.m`**: Benjamini-Hochberg false discovery rate procedure, by David M. Groppe
  (version 2.3, 2015), from the MATLAB Central File Exchange, submission 27418:
  https://www.mathworks.com/matlabcentral/fileexchange/27418-fdr_bh.
  - **License:** BSD. This is the standard license of code uploaded directly to the File
    Exchange ([File Exchange Licensing FAQ](https://www.mathworks.com/matlabcentral/content/fx/fx-transition-faq.html)).
    The license text with its copyright line is the `license.txt` in the File Exchange download.
  - **Changes:** none. The file is included unmodified.
  - **Use:** `code/lib/stats/wilcoxon_fdr.m` calls it as `fdr_bh(p, 0.05, 'pdep', 'no')`.
