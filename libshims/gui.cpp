#include <gui/BufferQueue.h>
#include <gui/SurfaceComposerClient.h>

using namespace android;

//void BufferQueue::createBufferQueue(sp<IGraphicBufferProducer>* outProducer,
//        sp<IGraphicBufferConsumer>* outConsumer,
//        bool consumerIsSurfaceFlinger) 
extern "C" void _ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEEb(
	sp<IGraphicBufferProducer>* outProducer,
        sp<IGraphicBufferConsumer>* outConsumer,
        bool consumerIsSurfaceFlinger); 

extern "C" void _ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEERKNS1_INS_19IGraphicBufferAllocEEE(
	sp<IGraphicBufferProducer>* outProducer,
        sp<IGraphicBufferConsumer>* outConsumer,
	void *allocator) {
	//const sp<IGraphicBufferAlloc>& allocator) {
	_ZN7android11BufferQueue17createBufferQueueEPNS_2spINS_22IGraphicBufferProducerEEEPNS1_INS_22IGraphicBufferConsumerEEEb(outProducer, outConsumer, false); //FIXME: check consumerIsSurfaceFlinger
}

// android::Fence::~Fence()
extern "C" void _ZN7android5FenceD1Ev() {
	// no-op, the explicit destructor was replaced with = default;
}

// Old vendor blobs (libgui_ext.so) call the pre-refactor
// SurfaceComposerClient::getBuiltInDisplay(int) API (id 0 = main/internal
// display, id 1 = HDMI). Modern libgui replaced it with
// getInternalDisplayToken() / getPhysicalDisplayToken(). Uses an asm label
// (not extern "C") since the return type is a non-POD C++ class.
sp<IBinder> shim_getBuiltInDisplay(int id)
		asm("_ZN7android21SurfaceComposerClient17getBuiltInDisplayEi");

sp<IBinder> shim_getBuiltInDisplay(int id) {
	if (id == 0) {
		return SurfaceComposerClient::getInternalDisplayToken();
	}
	std::vector<PhysicalDisplayId> ids = SurfaceComposerClient::getPhysicalDisplayIds();
	if (id > 0 && static_cast<size_t>(id) < ids.size()) {
		return SurfaceComposerClient::getPhysicalDisplayToken(ids[id]);
	}
	return nullptr;
}
