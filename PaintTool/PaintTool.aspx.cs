using System;
using System.Web.UI;
using System.IO;
using System.Drawing;
using System.Drawing.Imaging;


namespace PaintTool
{
    public partial class PaintTool : System.Web.UI.Page
    {
        protected void BtnUpload_Click(object sender, EventArgs e)
        {
            if (FileUpload1.HasFile)
            {
                string fileName = Path.GetFileName(FileUpload1.FileName);
                string savePath = Server.MapPath("~/Uploads/" + fileName);
                FileUpload1.SaveAs(savePath);

                string imageUrl = "~/Uploads/" + fileName;
                UploadedImagePath.Value = ResolveUrl(imageUrl);  
            }
        }

        protected void BtnDownloadCanvas_Click(object sender, EventArgs e)
        {
            try
            {
                string dataURL = CanvasDataURL.Value;
                if (string.IsNullOrEmpty(dataURL))
                {
                    throw new Exception("No canvas data provided.");
                }

                
                string base64String = dataURL.Replace("data:image/png;base64,", "");
                byte[] imageBytes = Convert.FromBase64String(base64String);

                
                using (MemoryStream ms = new MemoryStream(imageBytes))
                using (Bitmap bitmap = new Bitmap(ms))
                {
                    
                    Response.Clear();
                    Response.ContentType = "image/png";
                    Response.AddHeader("Content-Disposition", "attachment; filename=canvas_image.png");

                    
                    using (MemoryStream outputStream = new MemoryStream())
                    {
                        bitmap.Save(outputStream, ImageFormat.Png);
                        outputStream.WriteTo(Response.OutputStream);
                    }

                    Response.End();
                }
            }
            catch (Exception ex)
            {                
                Response.Write("Error downloading canvas: " + ex.Message);
            }
        }
    }

}

