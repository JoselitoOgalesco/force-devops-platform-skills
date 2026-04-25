# How to Create a Confluence Page from README

## 🎯 Quick Method (Recommended)

### Step 1: Delete the Current Page Content
1. In your Confluence page editor, select all the raw markup text (Ctrl/Cmd + A)
2. Delete it

### Step 2: Switch to HTML Source Mode
1. Click the **⚙️ (Settings)** icon in the toolbar → **View storage format**
   - OR click **</>** if available
   - OR press `Ctrl+Shift+D` (Windows) or `Cmd+Shift+D` (Mac)

### Step 3: Paste HTML Content
1. Open `README-CONFLUENCE-HTML.html` from this repository
2. Copy ALL the content (Ctrl/Cmd + A, then Ctrl/Cmd + C)
3. Paste it into the storage format editor
4. Click **Save** or **Close** to exit storage format mode

### Step 4: Publish
1. The page should now display properly formatted!
2. Click **Publish** in the top-right corner

---

## 📋 Alternative: Manual Copy-Paste (Easier)

If the HTML method doesn't work:

### Step 1-3: Same as Quick Method (delete content, create new page)

### Step 4: Copy from Rendered Markdown
1. Open `README.md` in GitHub or VS Code preview
2. Copy formatted sections one at a time:
   - Select a section in the rendered view
   - Paste into Confluence (it will preserve formatting!)

### Step 5: Adjust Tables
1. Use Confluence's table editor to create/edit tables
2. Copy table data row by row if needed

---

## ⚠️ Why Wiki Markup Didn't Work

Modern Confluence Cloud uses a rich text editor and **no longer supports wiki markup rendering** in the default editor. The `h1.`, `{code}`, and table syntax you pasted are treated as plain text, not formatting commands.

**Solutions:**
1. ✅ **Use HTML storage format** (recommended - see above)
2. ✅ **Copy-paste from rendered markdown** (easiest)
3. ❌ Don't use wiki markup in modern Confluence

---

## Alternative Method: Using the Source Editor

If the markup macro doesn't work or isn't available:

### Step 1-4: Same as above

### Step 5 (Alternative): Use Source Editor
1. Look for the **</>** icon in the toolbar (Source Editor)
2. Click it to open the HTML/source view
3. Manually convert the wiki markup to HTML, or
4. Contact your Confluence administrator to enable the Wiki Markup plugin

---

## Troubleshooting

### Issue: "Markup" option not available
**Solution:** Your Confluence instance may not have the Wiki Markup plugin enabled. Contact your Confluence administrator or use the manual formatting method below.

### Issue: Tables not rendering correctly
**Solution:** Ensure there are no extra spaces in the table syntax. Each row should start with `|` and end with `|`.

### Issue: Code blocks not showing
**Solution:** Verify the `{code}` macros are properly closed with `{code}`. For language-specific highlighting, use `{code:bash}` or `{code:java}`.

---

## Manual Formatting (If Wiki Markup Unavailable)

If you cannot use wiki markup, manually format the page:

1. **Headers**: Use the heading dropdown (H1, H2, H3)
2. **Tables**: Use Insert → Table
3. **Code blocks**: Use Insert → Code Block
4. **Inline code**: Use `Ctrl/Cmd + Shift + M` for monospace
5. **Bullets**: Use the bullet list button
6. **Bold**: Use `Ctrl/Cmd + B`

This will take longer but achieves the same result.

---

## Quick Reference: Confluence Wiki Markup

| Markup | Renders As |
|--------|-----------|
| `h1.` | Heading 1 |
| `h2.` | Heading 2 |
| `h3.` | Heading 3 |
| `*text*` | **Bold text** |
| `{{code}}` | `monospace` |
| `{code}...{code}` | Code block |
| `\|\| Header \|\|` | Table header |
| `\| Cell \|` | Table cell |
| `* item` | Bullet list |
| `# item` | Numbered list |
| `(/)` | ✓ Checkmark |

---

## Next Steps

After publishing:
1. Share the page link with your team
2. Add labels (tags) for easy discovery: `salesforce`, `ai`, `development`, `skills`
3. Add to your space's navigation or page tree
4. Set appropriate permissions if needed

---

## Support

If you encounter issues:
- Check Confluence documentation: https://confluence.atlassian.com/doc/
- Contact your Confluence administrator
- Try the manual formatting approach
