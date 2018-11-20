/*
 * rak833_rpi.h
 *
 *  Created on: Jun 14, 2018
 *      Author: Gavin.Gao
 */

#ifndef _RAK833_RPI_H_
#define _RAK833_RPI_H_

/* Human readable platform definition */
#define DISPLAY_PLATFORM "RAK833 + Rpi"

/* parameters for native spi */
#define SPI_SPEED		8000000
#define SPI_DEV_PATH	"/dev/spidev0.0"
#define SPI_CS_CHANGE   0

/* parameters for a FT2232H */
#define VID		        0x0403
#define PID		        0x6010

#endif /* _RAK833_RPI_H_ */