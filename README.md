# 300$ קרדיטים חינם ל-Google Cloud: כל מודלי ה-AI של גוגל, וסקיל שמגדיר הכל

ידעתם שגוגל נותנת 300$ לשימוש בענן שלה, ושאפשר לנצל אותם למודלי השפה שלה וליצירת סרטונים, תמונות, קריינות ומוזיקה עם AI? כאן מוסבר איך מקבלים את הקרדיט, ואפשר להוריד סקיל ל-Claude Code שעושה את כל ההגדרות בשבילכם.

**[⬇️ הורדת הסקיל: gcp-vertex-setup.zip](https://github.com/TovTechOrg/gcp-vertex-setup/releases/latest/download/gcp-vertex-setup.zip)**

## מה מקבלים

חשבון Google Cloud חדש מקבל 300$ קרדיט ל-90 יום. הקרדיט פותח גישה ישירה למודלים של גוגל ב-Vertex AI. כל המודלים ברשימה נבדקו בקריאה אמיתית באוקטובר 2026:

- ‏**Gemini 4:** מודל השפה החזק של גוגל, לכתיבה, קוד וניתוח מסמכים
- ‏**Gemini 3.8 Flash:** מהיר וזול, למשימות יומיומיות
- ‏**Gemini Transcribe:** תמלול הקלטות לטקסט
- ‏**Veo 3.1:** קטעי וידאו מציאותיים מתיאור בטקסט
- ‏**Gemini 3.8 TTS:** קריינות בקול טבעי
- ‏**Lyria 3 Pro:** מוזיקת רקע מקורית לפי תיאור
- ‏**Nano Banana 2.1:** תמונות, באנרים ותמונות לסרטונים

## איך מקבלים את 300$

נכנסים ל-[console.cloud.google.com/freetrial](https://console.cloud.google.com/freetrial) עם חשבון Google שלא היה לו בעבר חשבון Google Cloud. גוגל מבקשת פרטי כרטיס אשראי, ואפשר להתחיל מיד תוכנית קרדיטים של 300$ לשלושה חודשים.

הכרטיס משמש לאימות בלבד. אין חיוב אלא אם משדרגים בעצמכם לחשבון בתשלום. כשהקרדיט נגמר או כשעוברים 90 יום, השירותים פשוט נעצרים.

שימו לב: הקרדיט לא מכסה מודלים של שותפים כמו Claude, ולא את Gemini API דרך AI Studio. הוא מכסה את מודלי גוגל ב-Vertex AI.

## הסקיל: כל ההגדרות אוטומטית

אחרי ההרשמה מגיע החלק המייגע: פרויקט, חיבור חיוב, הפעלת APIs, Service Account, הרשאות, מפתח ומשתני סביבה. הסקיל עושה את כל זה דרך gcloud, ועוצר רק בשלבים שחייבים לעשות בעצמכם.

### מה הסקיל עושה לבד

- מתקין את gcloud CLI אם הוא חסר
- יוצר פרויקט ומחבר אותו לחשבון החיוב של ה-Free Trial
- מפעיל את Vertex AI ואת שאר ה-APIs הנדרשים
- יוצר Service Account עם הרשאת aiplatform.user ומפתח JSON
- מגדיר משתני סביבה קבועים, כך שכל סקריפט Python מתחבר בלי התחברות מחדש
- יוצר תקציב של 300$ עם התראות במייל ב-50%, 90% ו-100%
- בודק שהכל עובד בקריאה אמיתית ל-Gemini, ומציג את המודלים העדכניים שזמינים לכם

### מה עושים ידנית

- הזנת כרטיס האשראי ואישור התנאים בהרשמה
- התחברות לחשבון Google בדפדפן, פעם אחת
- בחשבון ארגוני (Google Workspace): ייתכן שמנהל הארגון יצטרך לאשר יצירת מפתחות. הסקיל מדפיס את הפקודה המדויקת

## התקנה

הדרך הקלה: כתבו ל-Claude Code

```
תתקין את הסקיל מ-https://github.com/TovTechOrg/gcp-vertex-setup ואז תגדיר לי Vertex AI עם 300 דולר קרדיטים
```

או ידנית:

1. הורידו את [gcp-vertex-setup.zip](https://github.com/TovTechOrg/gcp-vertex-setup/releases/latest/download/gcp-vertex-setup.zip) וחלצו אותו לתיקייה `%USERPROFILE%\.claude\skills\` (במק: `~/.claude/skills/`)
2. פתחו את Claude Code וכתבו: `תגדיר לי Vertex AI עם 300 דולר קרדיטים`
3. הסקיל שואל כמה שאלות, ומנחה אתכם בשלבים הידניים

או בשורה אחת ב-PowerShell:

```powershell
iwr https://github.com/TovTechOrg/gcp-vertex-setup/releases/latest/download/gcp-vertex-setup.zip -OutFile $env:TEMP\gcp.zip; Expand-Archive $env:TEMP\gcp.zip "$env:USERPROFILE\.claude\skills" -Force
```

הסקריפט כתוב ל-Windows PowerShell. במק ובלינוקס Claude יריץ את אותן פקודות gcloud ישירות.

## אבטחה

מפתח ה-JSON שהסקיל יוצר שווה כסף. אל תעלו אותו ל-GitHub, ל-Drive או לצ'אט. אם הוא דלף, מוחקים אותו מיד ב-IAM ויוצרים חדש.

## מה יש בריפו

| קובץ | מה הוא עושה |
| --- | --- |
| [`gcp-vertex-setup/SKILL.md`](gcp-vertex-setup/SKILL.md) | ההוראות ש-Claude Code קורא: השלבים, מה ידני ומה אוטומטי |
| [`gcp-vertex-setup/scripts/setup-vertex.ps1`](gcp-vertex-setup/scripts/setup-vertex.ps1) | הסקריפט שמריץ את כל פקודות ה-gcloud. אפשר להריץ אותו שוב בבטחה |

---

נבנה ב-[TovTech](https://github.com/TovTechOrg).
