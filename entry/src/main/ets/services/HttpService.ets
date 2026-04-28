import { http } from '@kit.NetworkKit';

export class HttpService {
  private static httpRequest: http.HttpRequest | null = null;

  private static async getRequest(): Promise<http.HttpRequest> {
    if (!HttpService.httpRequest) {
      HttpService.httpRequest = http.createHttp();
    }
    return HttpService.httpRequest!;
  }

  static async fetchIcs(url: string): Promise<string> {
    const request = await HttpService.getRequest();

    try {
      const response = await request.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 15000,
        readTimeout: 30000,
        header: {
          'Accept': 'text/calendar',
          'User-Agent': 'SportCalendar/1.0'
        }
      } as http.HttpRequestOptions);

      if (response.responseCode >= 200 && response.responseCode < 300) {
        return response.result as string;
      }

      throw new Error(`HTTP ${response.responseCode}: ${url}`);
    } catch (e) {
      if (e instanceof Error) {
        throw new Error(`网络请求失败: ${e.message}`);
      }
      throw new Error('网络请求失败');
    }
  }

  static destroy(): void {
    if (HttpService.httpRequest) {
      HttpService.httpRequest.destroy();
      HttpService.httpRequest = null;
    }
  }
}
