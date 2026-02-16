#ifndef _LINUX_I2C_H
#define _LINUX_I2C_H

#include <linux/types.h>

#define I2C_M_RD        0x0001
#define I2C_M_TEN       0x0010
#define I2C_M_RECV_LEN  0x0400
#define I2C_M_NO_RD_ACK 0x0800
#define I2C_M_IGNORE_NAK 0x1000
#define I2C_M_REV_DIR_ADDR 0x2000
#define I2C_M_NOSTART   0x4000
#define I2C_M_STOP      0x8000

struct i2c_msg {
	__u16 addr;
	__u16 flags;
	__u16 len;
	__u8 *buf;
};

struct i2c_rdwr_ioctl_data {
	struct i2c_msg *msgs;
	__u32 nmsgs;
};

#endif
