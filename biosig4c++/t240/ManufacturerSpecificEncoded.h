/*
 * Generated by asn1c-0.9.21 (http://lionet.info/asn1c)
 * From ASN.1 module "FEF-IntermediateDraft"
 * 	found in "../annexb-snacc-122001.asn1"
 */

#ifndef	_ManufacturerSpecificEncoded_H_
#define	_ManufacturerSpecificEncoded_H_


#include <asn_application.h>

/* Including external dependencies */
#include "PrivateCode.h"
#include <ANY.h>
#include <constr_SEQUENCE.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ManufacturerSpecificEncoded */
typedef struct ManufacturerSpecificEncoded {
	PrivateCode_t	 code;
	ANY_t	 data;
	
	/* Context for parsing across buffer boundaries */
	asn_struct_ctx_t _asn_ctx;
} ManufacturerSpecificEncoded_t;

/* Implementation */
extern asn_TYPE_descriptor_t asn_DEF_ManufacturerSpecificEncoded;

#ifdef __cplusplus
}
#endif

#endif	/* _ManufacturerSpecificEncoded_H_ */
