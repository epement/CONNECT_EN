_README.TXT - Translations from Russian to English were all done with
Google Translate at https://translate.google.com. This service permits
entering up to 5000 characters into the Text input form. Translations
of greater length must be done by either splitting the source file into
parts, or else by submitting a Word or PDF document into the Documents
file upload area.

This directory holds Word documents for longer Russian text files. My
usual process is to open the Russian source *.txt file in Notepad++,
set the encoding, copy the Russian text to the Windows clipboard, and
paste it into a new Microsoft Word document. Word generally recognized
the Russian (Cyrillic) characters without needing special setup.

Files from different directories are distinguished by long-filename
prefix. Input files ending with "_RU" are Russian/Cyrillic; output
files ending with "_EN" are the English/Latin translations provided by
Google Translate or Google Cloud Translation. More info from
https://cloud.google.com/translation-hub?hl=en

The normal process of file translation has 4 steps:
  1. SUBDIR-NAME_RU.docx        # submitted to Google Translate
  2. SUBDIR-NAME_EN.docx        # received from Google Translate
  3. SUBDIR-NAME_ENexport.txt   # docx "SaveAs DOS text", expect some loss
  4. SUBDIR-NAME_ENready.txt    # cleaned, ready to be copiled as HLP file

2026/04/04 13:18
