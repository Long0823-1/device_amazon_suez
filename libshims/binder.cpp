extern "C" int _ZNK7android6Parcel24readParcelFileDescriptorEv();

extern "C" int _ZNK7android6Parcel24readParcelFileDescriptorERi(int& outCommChannel) {
	return _ZNK7android6Parcel24readParcelFileDescriptorEv();
}

// Old vendor blobs (libbwc.so, libgui_ext.so) call IInterface::asBinder()
// as a no-arg member function (pre-refactor ABI). Modern libbinder only
// exposes it as the static IInterface::asBinder(const IInterface*). Provide
// the old mangled symbol, forwarding into the current implementation.
// Uses an asm label (not extern "C") since the return type is a non-POD
// C++ class, which extern "C" linkage disallows.
#include <binder/IInterface.h>

android::sp<android::IBinder> shim_asBinder(android::IInterface* iface)
		asm("_ZN7android10IInterface8asBinderEv");

android::sp<android::IBinder> shim_asBinder(android::IInterface* iface) {
	return android::IInterface::asBinder(iface);
}
