using System;
using System.Web.UI;
using System.IO;

namespace PaintTool
{
    public partial class PaintTool : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
        }

        protected void BtnUpload_Click(object sender, EventArgs e)
        {
            if (FileUpload1.HasFile)
            {
                string fileName = Path.GetFileName(FileUpload1.FileName);
                string savePath = Server.MapPath("~/Uploads/" + fileName);
                FileUpload1.SaveAs(savePath);

                string imageUrl = "~/Uploads/" + fileName;
                UploadedImagePath.Value = ResolveUrl(imageUrl);  // Sets image path for JavaScript
            }
        }



    }
}
