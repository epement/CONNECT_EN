_README.TXT - Translations from Russian to English were all done with
Google Translate at https://translate.google.com. This service permits
entering up to 5000 characters into the Text input form. Translations
of greater length must be done by either splitting the source file into
parts, or else by submitting a Word or PDF document into the Documents
file upload area.

NOTE: translations done by text input use the Gemini AI model for
translation, which is excellent. Translations done by file upload use the
Classic translation model, which is poor and literal, but better than
nothing. In most cases, it is far better to take a long textfile and
split it into chunks rather than submit a Word document.

This directory holds Word documents for longer Russian text files. My
original process was to open the Russian source *.txt file in Notepad++,
set the encoding, copy the Russian text to the Windows clipboard, and
paste it into a new Microsoft Word document. Word generally recognized
the Russian (Cyrillic) characters without needing special setup.
Although this works, the poor output of the Classic translation engine
forces me to split long files into 5000-word chunks.

Files from different directories are distinguished by long-filename
prefix. Input files ending with "_RU" are Russian/Cyrillic; output
files ending with "_EN" are the English/Latin translations provided by
Google Translate or Google Cloud Translation. More info from
https://cloud.google.com/translation-hub?hl=en

The normal process of file translation has 4 steps:
  1. SUBDIR-NAME_RU.docx        # submitted to Google Translate
  2. SUBDIR-NAME_EN.docx        # received from Google Translate
  3. SUBDIR-NAME_ENexport.txt   # docx "SaveAs DOS text", expect some loss
  4. SUBDIR-NAME_ENready.txt    # cleaned, ready to be compiled as HLP file

2026-04-07 11:49:15

---

New process: CONNECT.TXT (orig name of CN3_RU.TXT) is the source code
for the CONNECT.HLP file. However, it's 347,618 bytes in size and
splitting it into 5K chunks for Google translate would require almost
70 separate files, and I don't have the patience for that. DeepL
(www.deepl.com) has good reviews for AI language translation. I paid
$10.49 for one month or 300,000 chars, which gets me most of the
way there. DeepL also supports file uploads in .txt format.

The returned file ("CN3aa_RU en-US.docx") translation looks good and is
adequate for export or copy/paste back to .txt format.

2026/05/01 12:10 pm
