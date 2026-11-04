using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Windows.Forms;
using BTLib;


namespace winceBT
{
    public partial class winceBT : Form
    {
        OperateBt mDev = null;
        BluetoothDeviceInfo[] btList = null;
        private int iSearchFlag = 0;
        
        public winceBT()
        {
            InitializeComponent();
        }

        private void winceBT_Load(object sender, EventArgs e)
        {
            mDev = new OperateBt();
        }
        
        private void btn_conn_Click(object sender, EventArgs e)
        {
            if (string.Compare(this.btn_conn.Text.ToString(), "连接") == 0) 
            {
                int loop = 0;
                for (loop = 0; loop < btList.Length; loop++)
                {
                    if (string.Compare(this.cbx_listdev.Text.ToString(), this.btList[loop].DeviceName) == 0)
                    {
                        break;
                    }
                }
                try
                {
                    if (this.btList[loop].DeviceID == null) {
                        MessageBox.Show("设备地址不能为空");
                        return;
                    }
                    mDev.BtConnect(this.btList[loop].DeviceID);
                    MessageBox.Show("连接打印机成功！！");
                    this.btn_conn.Text = "关闭";
                }
                catch (Exception ex)
                {
                    MessageBox.Show(ex.Message);
                }

            }
            else if (string.Compare(this.btn_conn.Text.ToString(), "关闭") == 0) {
                mDev.BtCloseConn();
                this.btn_conn.Text = "连接";
            }

        }

        private void btn_discover_Click(object sender, EventArgs e)
        {
            try
            {
                if (iSearchFlag == 0)
                {
                    iSearchFlag = 1;
                    this.Text = "正在搜索......";
                    this.cbx_listdev.DataSource = null;
                    this.btList = this.mDev.Discover_BlueTooth_Devices();
                    this.cbx_listdev.DataSource = this.btList;
                    this.cbx_listdev.DisplayMember = "DeviceName";
                    this.Text = "搜索完毕";
                    iSearchFlag = 0;
                }
            }
            catch (Exception ex)
            {
                iSearchFlag = 0;
                MessageBox.Show(ex.Message);
            }
            Application.DoEvents();
        }

        private void btn_send_Click(object sender, EventArgs e)
        {
            byte[] OutBuffer;
            byte[] cmd = new byte[3];
            Encoding targetEncoding;   
            string strMsg = this.txt_msg.Text.ToString() + "\n";
            try
            {
                cmd[0] = 0x1b;
                cmd[1] = 0x21;
                if (cbxDoubleWidth.Checked == true)
                {
                    cmd[2] |= 0x20;
                }
                else 
                {
                    cmd[2] &= 0xDF;
                }
                if (cbxDoubleHeight.Checked == true)
                {
                    cmd[2] |= 0x10;
                }
                else 
                {
                    cmd[2] &= 0xEF;
                }
                mDev.BtSend(cmd);
                targetEncoding = Encoding.GetEncoding(0);
                OutBuffer = targetEncoding.GetBytes(strMsg);
                mDev.BtSend(OutBuffer);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void btn_opt_Click(object sender, EventArgs e)
        {
            BluetoothRadioMode mod = BluetoothRadioMode.On;
            int ret = mDev.BtGetMode(ref mod);
            MessageBox.Show(mod.ToString());
            ret = 0;
            try
            {
                ret = mDev.BthSetMode(BluetoothRadioMode.Off);
                MessageBox.Show("返回结果为"+ret.ToString());
            }
            catch (Exception ex) 
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void btnClear_Click(object sender, EventArgs e)
        {
            this.txt_msg.Text = "";
        }

        private void btnFeedPaper_Click(object sender, EventArgs e)
        {
            byte[] cmd = new byte[2];
            cmd[0] = 0x0A;
            try
            {
                mDev.BtSend(cmd);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
            }
        }

        private void txt_msg_TextChanged(object sender, EventArgs e)
        {

        }
    }
}




