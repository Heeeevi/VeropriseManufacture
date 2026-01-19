import { useState, useEffect } from 'react';
import { Calendar, Clock, AlertCircle, CheckCircle, XCircle } from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { supabase } from '@/integrations/supabase/client';
import { ATTENDANCE_STATUS_LABELS, ATTENDANCE_STATUS_COLORS } from '@/types/hr';

export function AttendanceDashboard() {
  const [outlets, setOutlets] = useState<any[]>([]);
  const [selectedOutlet, setSelectedOutlet] = useState('');
  const [selectedDate, setSelectedDate] = useState(new Date().toISOString().split('T')[0]);
  const [attendances, setAttendances] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchOutlets();
  }, []);

  useEffect(() => {
    if (selectedOutlet) {
      fetchAttendances();
    }
  }, [selectedOutlet, selectedDate]);

  const fetchOutlets = async () => {
    const { data } = await supabase
      .from('outlets')
      .select('*')
      .eq('is_active', true);
    setOutlets(data || []);
  };

  const fetchAttendances = async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from('attendance')
        .select(`
          *,
          employee:employees(name, phone),
          shift:shifts(name, start_time, end_time)
        `)
        .eq('outlet_id', selectedOutlet)
        .gte('date', selectedDate)
        .lte('date', selectedDate)
        .order('date', { ascending: false });

      if (error) throw error;
      setAttendances(data || []);
    } catch (error) {
      console.error('Error fetching attendances:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleClockIn = async (attendanceId: string) => {
    try {
      const { error } = await supabase
        .from('attendance')
        .update({
          clock_in: new Date().toISOString(),
          status: 'present',
        })
        .eq('id', attendanceId);

      if (error) throw error;
      alert('Clock in berhasil!');
      fetchAttendances();
    } catch (error) {
      console.error('Clock in error:', error);
      alert('Gagal clock in');
    }
  };

  const handleClockOut = async (attendanceId: string) => {
    try {
      const { error } = await supabase
        .from('attendance')
        .update({
          clock_out: new Date().toISOString(),
        })
        .eq('id', attendanceId);

      if (error) throw error;
      alert('Clock out berhasil!');
      fetchAttendances();
    } catch (error) {
      console.error('Clock out error:', error);
      alert('Gagal clock out');
    }
  };

  const stats = {
    present: attendances.filter(a => a.status === 'present').length,
    late: attendances.filter(a => a.status === 'late').length,
    absent: attendances.filter(a => a.status === 'absent').length,
    pending: attendances.filter(a => a.status === 'pending').length,
  };

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Absensi Karyawan</h1>
        <p className="text-gray-600">Monitor kehadiran karyawan (auto-generated dari shift)</p>
      </div>

      {/* Filters */}
      <Card>
        <CardContent className="pt-6">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <Select value={selectedOutlet} onValueChange={setSelectedOutlet}>
                <SelectTrigger>
                  <SelectValue placeholder="Pilih outlet" />
                </SelectTrigger>
                <SelectContent>
                  {outlets.map(o => (
                    <SelectItem key={o.id} value={o.id}>{o.name}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="w-full px-3 py-2 border rounded-md"
              />
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Stats */}
      {selectedOutlet && (
        <div className="grid grid-cols-4 gap-4">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Hadir</p>
                  <p className="text-2xl font-bold text-green-600">{stats.present}</p>
                </div>
                <CheckCircle className="h-8 w-8 text-green-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Terlambat</p>
                  <p className="text-2xl font-bold text-orange-600">{stats.late}</p>
                </div>
                <Clock className="h-8 w-8 text-orange-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Tidak Hadir</p>
                  <p className="text-2xl font-bold text-red-600">{stats.absent}</p>
                </div>
                <XCircle className="h-8 w-8 text-red-600" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-sm text-gray-600">Pending</p>
                  <p className="text-2xl font-bold text-gray-600">{stats.pending}</p>
                </div>
                <AlertCircle className="h-8 w-8 text-gray-600" />
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Attendance List */}
      {selectedOutlet && (
        <Card>
          <CardHeader>
            <CardTitle>Daftar Absensi ({attendances.length})</CardTitle>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="text-center py-8">Loading...</div>
            ) : attendances.length === 0 ? (
              <div className="text-center py-8 text-gray-500">
                <Calendar className="h-12 w-12 mx-auto mb-4 text-gray-400" />
                <p>Belum ada data absensi untuk tanggal ini</p>
                <p className="text-sm mt-2">Absensi otomatis dibuat dari jadwal shift</p>
              </div>
            ) : (
              <div className="space-y-3">
                {attendances.map((attendance) => (
                  <div key={attendance.id} className="p-4 border rounded-lg">
                    <div className="flex items-center justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-3">
                          <div>
                            <p className="font-semibold">{attendance.employee?.name}</p>
                            <p className="text-sm text-gray-600">
                              Shift: {attendance.shift?.name} ({attendance.shift?.start_time} - {attendance.shift?.end_time})
                            </p>
                          </div>
                          <Badge className={ATTENDANCE_STATUS_COLORS[attendance.status as keyof typeof ATTENDANCE_STATUS_COLORS]}>
                            {ATTENDANCE_STATUS_LABELS[attendance.status as keyof typeof ATTENDANCE_STATUS_LABELS]}
                          </Badge>
                        </div>
                      </div>

                      <div className="flex items-center gap-4">
                        <div className="text-right text-sm">
                          {attendance.clock_in ? (
                            <>
                              <p className="text-gray-600">Clock In</p>
                              <p className="font-semibold">
                                {new Date(attendance.clock_in).toLocaleTimeString('id-ID', {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </p>
                            </>
                          ) : (
                            <p className="text-gray-400">Belum clock in</p>
                          )}
                        </div>

                        <div className="text-right text-sm">
                          {attendance.clock_out ? (
                            <>
                              <p className="text-gray-600">Clock Out</p>
                              <p className="font-semibold">
                                {new Date(attendance.clock_out).toLocaleTimeString('id-ID', {
                                  hour: '2-digit',
                                  minute: '2-digit'
                                })}
                              </p>
                            </>
                          ) : attendance.clock_in ? (
                            <p className="text-orange-600 font-semibold">Sedang kerja</p>
                          ) : (
                            <p className="text-gray-400">-</p>
                          )}
                        </div>

                        <div className="flex gap-2">
                          {!attendance.clock_in && attendance.status === 'pending' && (
                            <Button
                              size="sm"
                              onClick={() => handleClockIn(attendance.id)}
                            >
                              Clock In
                            </Button>
                          )}
                          {attendance.clock_in && !attendance.clock_out && (
                            <Button
                              size="sm"
                              variant="outline"
                              onClick={() => handleClockOut(attendance.id)}
                            >
                              Clock Out
                            </Button>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Additional Info */}
                    <div className="mt-3 pt-3 border-t text-xs text-gray-600 grid grid-cols-3 gap-4">
                      {attendance.late_minutes > 0 && (
                        <div>
                          <span className="text-orange-600 font-semibold">
                            Terlambat: {attendance.late_minutes} menit
                          </span>
                        </div>
                      )}
                      {attendance.overtime_minutes > 0 && (
                        <div>
                          <span className="text-blue-600 font-semibold">
                            Lembur: {attendance.overtime_minutes} menit
                          </span>
                        </div>
                      )}
                      {attendance.notes && (
                        <div className="col-span-3">
                          <span className="italic">Catatan: {attendance.notes}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {selectedOutlet && (
        <Card className="bg-blue-50 border-blue-200">
          <CardContent className="pt-6">
            <h4 className="font-semibold text-sm mb-2">ℹ️ Cara Kerja Auto-Attendance:</h4>
            <ul className="text-xs text-gray-700 space-y-1">
              <li>1. Admin buat jadwal shift (assign karyawan ke shift)</li>
              <li>2. Sistem otomatis buat record attendance untuk hari itu</li>
              <li>3. Karyawan clock in (sistem cek keterlambatan)</li>
              <li>4. Karyawan clock out (sistem hitung lembur jika ada)</li>
              <li>5. Data attendance digunakan untuk payroll & incentive</li>
            </ul>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
