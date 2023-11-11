#include <vector>
#include <fstream>
#include "script_or_zone_file.h"
#include "core/framework.h"
#include "core/common.h"

ScriptOrZoneFile::ScriptOrZoneFile(std::filesystem::path path, const char *url) {
    this->path = path;
    this->url = url;
}

void ScriptOrZoneFile::updateFile() {
    Message("[ScriptOrZoneFile] Sending HTTP Request -> %s\n", this->url);
    auto req = Framework::SteamHTTP()->CreateHTTPRequest(k_EHTTPMethodGET, this->url);

    std::unique_ptr<HTTPCallback> http_callback = std::make_unique<HTTPCallback>();
    http_callback->SetGameserverFlag();

    Framework::SteamHTTP()->SetHTTPRequestContextValue(req, reinterpret_cast<uintptr_t>(http_callback.get()));


    SteamAPICall_t call;
    if (!Framework::SteamHTTP()->SendHTTPRequest(req, &call)) {
        Message("[ScriptOrZoneFile] Failed to send HTTP Request -> %s\n", this->url);
        return;
    }

    http_callback->Set(call, this, &ScriptOrZoneFile::handleHTTPResponse);
    this->http_callbacks.emplace_back(std::move(http_callback));
}

void ScriptOrZoneFile::handleHTTPResponse(HTTPRequestCompleted_t *response, bool failed) {
    Message("[ScriptOrZoneFile] Received Response -> %s\n", this->url);

    for (std::unique_ptr<HTTPCallback>& http_callback : this->http_callbacks)
    {
        if (reinterpret_cast<uintptr_t>(http_callback.get()) == response->m_ulContextValue)
        {
            std::swap(http_callback, this->http_callbacks.back());
            this->http_callbacks.pop_back();
        }
    }

    uint32_t responseSize;
    Framework::SteamHTTP()->GetHTTPResponseBodySize(response->m_hRequest, &responseSize);
    std::vector<uint8_t> responseData(responseSize);
    Framework::SteamHTTP()->GetHTTPResponseBodyData(response->m_hRequest, responseData.data(), responseSize);

    Message("[ScriptOrZoneFile] Writing to file -> %s\n", this->path.string().data());

    std::ofstream file;
    file.open(this->path);
    file.write(reinterpret_cast<const char *>(responseData.data()), responseSize);
    file.close();
}