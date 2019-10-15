
RdcDocument 'Domain' {
	RdcADGroup -Recurse
	RdcLogonCredential @{
		Username = 'pa-erudakov'
		Domain   = 'medline.com'
	}
}