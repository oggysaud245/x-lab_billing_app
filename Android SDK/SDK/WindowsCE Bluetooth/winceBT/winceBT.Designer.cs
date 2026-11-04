namespace winceBT
{
    partial class winceBT
    {
        /// <summary>
        /// 必需的设计器变量。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清理所有正在使用的资源。
        /// </summary>
        /// <param name="disposing">如果应释放托管资源，为 true；否则为 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows 窗体设计器生成的代码

        /// <summary>
        /// 设计器支持所需的方法 - 不要
        /// 使用代码编辑器修改此方法的内容。
        /// </summary>
        private void InitializeComponent()
        {
            this.cbx_listdev = new System.Windows.Forms.ComboBox();
            this.btn_conn = new System.Windows.Forms.Button();
            this.txt_msg = new System.Windows.Forms.TextBox();
            this.btn_send = new System.Windows.Forms.Button();
            this.label1 = new System.Windows.Forms.Label();
            this.btn_discover = new System.Windows.Forms.Button();
            this.cbxDoubleHeight = new System.Windows.Forms.CheckBox();
            this.cbxDoubleWidth = new System.Windows.Forms.CheckBox();
            this.btnClear = new System.Windows.Forms.Button();
            this.btnFeedPaper = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // cbx_listdev
            // 
            this.cbx_listdev.Location = new System.Drawing.Point(13, 45);
            this.cbx_listdev.Name = "cbx_listdev";
            this.cbx_listdev.Size = new System.Drawing.Size(206, 23);
            this.cbx_listdev.TabIndex = 1;
            // 
            // btn_conn
            // 
            this.btn_conn.Location = new System.Drawing.Point(13, 74);
            this.btn_conn.Name = "btn_conn";
            this.btn_conn.Size = new System.Drawing.Size(206, 29);
            this.btn_conn.TabIndex = 2;
            this.btn_conn.Text = "连接";
            this.btn_conn.Click += new System.EventHandler(this.btn_conn_Click);
            // 
            // txt_msg
            // 
            this.txt_msg.Location = new System.Drawing.Point(13, 133);
            this.txt_msg.Multiline = true;
            this.txt_msg.Name = "txt_msg";
            this.txt_msg.Size = new System.Drawing.Size(206, 69);
            this.txt_msg.TabIndex = 3;
            this.txt_msg.Text = "我公司是一家专业从事研发，生产，销售商用票据打印机和条码扫描设备于一体的高科技企业。";
            this.txt_msg.TextChanged += new System.EventHandler(this.txt_msg_TextChanged);
            // 
            // btn_send
            // 
            this.btn_send.Location = new System.Drawing.Point(15, 234);
            this.btn_send.Name = "btn_send";
            this.btn_send.Size = new System.Drawing.Size(57, 28);
            this.btn_send.TabIndex = 4;
            this.btn_send.Text = "打印";
            this.btn_send.Click += new System.EventHandler(this.btn_send_Click);
            // 
            // label1
            // 
            this.label1.Location = new System.Drawing.Point(13, 110);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(105, 20);
            this.label1.Text = "请输入信息：";
            // 
            // btn_discover
            // 
            this.btn_discover.Location = new System.Drawing.Point(13, 12);
            this.btn_discover.Name = "btn_discover";
            this.btn_discover.Size = new System.Drawing.Size(206, 27);
            this.btn_discover.TabIndex = 5;
            this.btn_discover.Text = "搜索";
            this.btn_discover.Click += new System.EventHandler(this.btn_discover_Click);
            // 
            // cbxDoubleHeight
            // 
            this.cbxDoubleHeight.Location = new System.Drawing.Point(77, 208);
            this.cbxDoubleHeight.Name = "cbxDoubleHeight";
            this.cbxDoubleHeight.Size = new System.Drawing.Size(69, 20);
            this.cbxDoubleHeight.TabIndex = 9;
            this.cbxDoubleHeight.Text = "倍高";
            // 
            // cbxDoubleWidth
            // 
            this.cbxDoubleWidth.Location = new System.Drawing.Point(152, 208);
            this.cbxDoubleWidth.Name = "cbxDoubleWidth";
            this.cbxDoubleWidth.Size = new System.Drawing.Size(69, 20);
            this.cbxDoubleWidth.TabIndex = 10;
            this.cbxDoubleWidth.Text = "倍宽";
            // 
            // btnClear
            // 
            this.btnClear.Location = new System.Drawing.Point(165, 235);
            this.btnClear.Name = "btnClear";
            this.btnClear.Size = new System.Drawing.Size(54, 27);
            this.btnClear.TabIndex = 12;
            this.btnClear.Text = "清空";
            this.btnClear.Click += new System.EventHandler(this.btnClear_Click);
            // 
            // btnFeedPaper
            // 
            this.btnFeedPaper.Location = new System.Drawing.Point(97, 234);
            this.btnFeedPaper.Name = "btnFeedPaper";
            this.btnFeedPaper.Size = new System.Drawing.Size(48, 27);
            this.btnFeedPaper.TabIndex = 13;
            this.btnFeedPaper.Text = "走纸";
            this.btnFeedPaper.Click += new System.EventHandler(this.btnFeedPaper_Click);
            // 
            // winceBT
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.AutoScroll = true;
            this.ClientSize = new System.Drawing.Size(638, 455);
            this.Controls.Add(this.btnFeedPaper);
            this.Controls.Add(this.btnClear);
            this.Controls.Add(this.cbxDoubleWidth);
            this.Controls.Add(this.cbxDoubleHeight);
            this.Controls.Add(this.btn_discover);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.btn_send);
            this.Controls.Add(this.txt_msg);
            this.Controls.Add(this.btn_conn);
            this.Controls.Add(this.cbx_listdev);
            this.Name = "winceBT";
            this.Text = "winceBT";
            this.WindowState = System.Windows.Forms.FormWindowState.Maximized;
            this.Load += new System.EventHandler(this.winceBT_Load);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.ComboBox cbx_listdev;
        private System.Windows.Forms.Button btn_conn;
        private System.Windows.Forms.TextBox txt_msg;
        private System.Windows.Forms.Button btn_send;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Button btn_discover;
        private System.Windows.Forms.CheckBox cbxDoubleHeight;
        private System.Windows.Forms.CheckBox cbxDoubleWidth;
        private System.Windows.Forms.Button btnClear;
        private System.Windows.Forms.Button btnFeedPaper;
    }
}

